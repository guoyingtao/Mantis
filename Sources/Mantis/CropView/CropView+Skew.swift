//
//  CropView+Skew.swift
//  Mantis
//
//  Extracted from CropView.swift
//

import UIKit

/// Groups the mutable state used to smooth and stabilize skew transforms
/// across consecutive frames. Replacing three loose properties on CropView
/// with a single value type makes reset sites explicit and concise.
struct SkewState {
    /// Previous compensating scale — prevents single-frame spikes when
    /// switching between skew axes (e.g. vertical → horizontal).
    var previousScale: CGFloat = 1.0
    
    /// Previous contentInset — rate-limits decreases when certain combined
    /// angles cause the polygon test to fail transiently.
    var previousInset: UIEdgeInsets = .zero
    
    /// Previous "optimal" content offset — subsequent skew changes apply a
    /// delta to the user's current position rather than snapping back.
    /// Nil when skew is zero (first change will set the offset directly).
    var previousOptimalOffset: CGPoint?
    
    /// Resets all tracked state back to defaults.
    mutating func reset() {
        previousScale = 1.0
        previousInset = .zero
        previousOptimalOffset = nil
    }
}

// MARK: - Skew / Perspective Transform
extension CropView {
    /// Returns the effective skew degrees after accounting for flip state.
    /// The viewModel stores the user-facing (SlideDial-displayed) value;
    /// flipping mirrors the perspective, so the sign must be inverted for
    /// the axis that matches the flip direction.
    var effectiveHorizontalSkewDegrees: CGFloat {
        var deg = viewModel.horizontalSkewDegrees
        if viewModel.horizontallyFlip { deg = -deg }
        return deg
    }
    
    var effectiveVerticalSkewDegrees: CGFloat {
        var deg = viewModel.verticalSkewDegrees
        if viewModel.verticallyFlip { deg = -deg }
        return deg
    }

    /// Returns the crop box corners in the scroll view's LOCAL coordinate system,
    /// expressed as displacements from the scroll view center.
    ///
    /// The crop box is an axis-aligned rectangle in screen space. The scroll view
    /// is rotated by `totalRadians`, so in local space the visible rectangle is
    /// the crop box rotated by `-totalRadians`. Using these corners instead of the
    /// axis-aligned bounding box (bounds) avoids over-conservative containment
    /// tests — the AABB at 45° is ~41% larger than the actual visible rectangle.
    var visibleCropCornersInScrollViewSpace: [CGPoint] {
        let cropW = cropAuxiliaryIndicatorView.frame.width
        let cropH = cropAuxiliaryIndicatorView.frame.height
        let halfWidth = cropW / 2
        let halfHeight = cropH / 2
        
        // The crop box is axis-aligned in screen space. The scroll view's
        // transform includes both rotation and (when flipped) a mirror.
        // To get the crop corners in scroll view local space we need to
        // apply the INVERSE of the scroll view's transform.
        //
        // Using the actual inverse guarantees correctness regardless of
        // flip state, rotation amount, or combination thereof.
        let inv = cropWorkbenchView.transform.inverted()
        
        // Screen-space corners relative to center, transformed to local space.
        let corners: [(CGFloat, CGFloat)] = [
            (-halfWidth, -halfHeight),  // TL
            ( halfWidth, -halfHeight),  // TR
            ( halfWidth,  halfHeight),  // BR
            (-halfWidth,  halfHeight)   // BL
        ]
        
        return corners.map { (cx, cy) in
            CGPoint(
                x: cx * inv.a + cy * inv.c,
                y: cx * inv.b + cy * inv.d
            )
        }
    }

    /// Whether the crop box currently matches the image's aspect ratio closely
    /// enough for edge-to-edge alignment to be meaningful. When the user has
    /// chosen a different ratio (e.g. 1:1 on a landscape image), the crop box
    /// vertices naturally touch two opposite image edges from the start, so the
    /// edge-to-edge phase should be skipped entirely.
    var cropBoxMatchesImageAspectRatio: Bool {
        let cropW = cropAuxiliaryIndicatorView.frame.width
        let cropH = cropAuxiliaryIndicatorView.frame.height
        let imgW = imageContainer.frame.width
        let imgH = imageContainer.frame.height
        guard cropH > 0 && imgH > 0 else { return true }
        let cropRatio = cropW / cropH
        let imgRatio = imgW / imgH
        // Allow ~5% tolerance for rounding
        return abs(cropRatio - imgRatio) / max(cropRatio, imgRatio) < 0.05
    }
    
    /// Applies the perspective (3D) skew transform to the crop workbench view's layer.
    /// The compensating scale is the exact minimum so the projected image just
    /// covers the crop box, producing an inscribed fit that matches Apple Photos.
    ///
    /// For small skew angles (≤ ~10°), a small extra scale boost is applied so
    /// the projected image has enough headroom for the edge-to-edge content
    /// offset positioning in `updateContentInsetForSkew`.
    func applySkewTransformIfNeeded() {
        let hDeg = effectiveHorizontalSkewDegrees
        let vDeg = effectiveVerticalSkewDegrees
        
        if hDeg == 0 && vDeg == 0 {
            cropWorkbenchView.layer.sublayerTransform = CATransform3DIdentity
            cropWorkbenchView.contentInset = .zero
            skewState.reset()
        } else {
            let zoomScale = max(cropWorkbenchView.zoomScale, 1)
            let perspectiveTransform =
                PerspectiveTransformHelper.combinedSkewTransform3D(
                    horizontalDegrees: hDeg,
                    verticalDegrees: vDeg,
                    zoomScale: zoomScale
                )
            
            // A small safety inset (2pt) guards against sub-pixel rounding
            // that could leave a hairline gap at the crop box edge.
            let (cornerDisplacements, visibleCornerDisplacements, _, _) =
                computeSkewProjectionInputs(safetyInset: 2)
            let rawScale = PerspectiveTransformHelper.computeCompensatingScale(
                imageCornerDisplacements: cornerDisplacements,
                visibleCornerDisplacements: visibleCornerDisplacements,
                perspectiveTransform: perspectiveTransform
            )
            
            let edgeBoost = computeEdgeToEdgeScaleBoost(hDeg: hDeg, vDeg: vDeg)
            
            var finalScale = rawScale * edgeBoost
            
            // Guard against degenerate values
            if !finalScale.isFinite || finalScale < 1.0 {
                finalScale = max(skewState.previousScale, 1.0)
            }
            
            skewState.previousScale = finalScale
            
            let scaledTransform = CATransform3DScale(perspectiveTransform, finalScale, finalScale, 1)
            cropWorkbenchView.layer.sublayerTransform = scaledTransform
        }
    }
    
    /// Recomputes contentInset for the current skew transform so the user
    /// can pan within the projected image area. Call this only when skew
    /// degrees actually change, NOT during every rotation frame.
    func updateContentInsetForSkew() {
        let hDeg = effectiveHorizontalSkewDegrees
        let vDeg = effectiveVerticalSkewDegrees

        guard hDeg != 0 || vDeg != 0 else {
            resetSkewInsetState()
            return
        }

        let transform = cropWorkbenchView.layer.sublayerTransform
        guard !CATransform3DIsIdentity(transform) else {
            resetSkewInsetState()
            return
        }

        let context = SkewInsetContext(
            imageFrame: imageContainer.frame,
            boundsSize: cropWorkbenchView.bounds.size,
            contentSize: cropWorkbenchView.contentSize,
            cropCorners: visibleCropCornersInScrollViewSpace,
            transform: transform
        )

        let newInset: UIEdgeInsets

        if isValidSkewPosition(shiftX: 0, shiftY: 0, context: context) {
            let shifts = computeMaxShifts(context: context)
            newInset = computeSkewContentInset(shifts: shifts, context: context)

            let optimalOffset = computeOptimalSkewOffset(
                hDeg: hDeg, vDeg: vDeg, shifts: shifts, context: context
            )
            applySkewContentOffset(optimalOffset: optimalOffset, inset: newInset, context: context)
        } else {
            // Center-based test fails — the projected image at the center
            // anchor is too small to cover the crop box. Lock to center.
            newInset = computeLockedCenterInset(context: context)
        }

        // Guard against non-finite inset values that can arise from
        // degenerate perspective projections at extreme zoom levels.
        guard newInset.top.isFinite && newInset.left.isFinite
                && newInset.bottom.isFinite && newInset.right.isFinite else {
            return
        }

        skewState.previousInset = newInset
        cropWorkbenchView.contentInset = newInset
    }
    
    /// After the user finishes dragging, verify that the crop box still lies
    /// inside the projected (skewed) image quad. If it doesn't, animate the
    /// contentOffset back to the nearest valid position.
    ///
    /// Because the single-axis insets form a rectangle that over-approximates
    /// the true (non-rectangular) valid region, the user can reach corners of
    /// the inset rectangle that are outside the valid region. This function
    /// performs a precise per-point perspective test and pulls back if needed.
    func clampContentOffsetForSkewIfNeeded() {
        let hDeg = effectiveHorizontalSkewDegrees
        let vDeg = effectiveVerticalSkewDegrees
        guard hDeg != 0 || vDeg != 0 else { return }

        let transform = cropWorkbenchView.layer.sublayerTransform
        guard !CATransform3DIsIdentity(transform) else { return }

        let context = SkewInsetContext(
            imageFrame: imageContainer.frame,
            boundsSize: cropWorkbenchView.bounds.size,
            contentSize: cropWorkbenchView.contentSize,
            cropCorners: visibleCropCornersInScrollViewSpace,
            transform: transform
        )

        let curOffset = cropWorkbenchView.contentOffset

        // First, clamp to inset bounds (standard scroll view range).
        let inset = cropWorkbenchView.contentInset
        let maxOffsetX = context.contentSize.width - context.boundsSize.width + inset.right
        let maxOffsetY = context.contentSize.height - context.boundsSize.height + inset.bottom
        var targetX = max(-inset.left, min(maxOffsetX, curOffset.x))
        var targetY = max(-inset.top, min(maxOffsetY, curOffset.y))

        if !isValidSkewOffset(ox: targetX, oy: targetY, context: context) {
            let cx = context.centerOffset.x
            let cy = context.centerOffset.y

            if isValidSkewOffset(ox: cx, oy: cy, context: context) {
                // Binary-search along the line from current position toward center
                // to find the nearest valid point.
                var lo: CGFloat = 0  // center
                var hi: CGFloat = 1  // current position
                for _ in 0..<16 {
                    let mid = (lo + hi) / 2
                    let testX = cx + (targetX - cx) * mid
                    let testY = cy + (targetY - cy) * mid
                    if isValidSkewOffset(ox: testX, oy: testY, context: context) {
                        lo = mid
                    } else {
                        hi = mid
                    }
                }
                targetX = cx + (targetX - cx) * lo
                targetY = cy + (targetY - cy) * lo
            } else {
                // At extreme skew angles the polygon containment test can
                // reject even the image center due to floating-point limits.
                // Fall back to the center — it is geometrically the safest
                // position and keeps the crop box within the image.
                targetX = cx
                targetY = cy
            }
        }

        let target = CGPoint(x: targetX, y: targetY)
        guard target.x.isFinite && target.y.isFinite,
              target != curOffset else { return }

        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            self.cropWorkbenchView.contentOffset = target
        }
    }
    
    /// Synchronizes the SlideDial's internal stored angles and button values
    /// with the CropView's viewModel skew degrees (e.g. after a 90° rotation swap).
    func syncSlideDialSkewValues() {
        guard let slideDial = rotationControlView as? SlideDial else { return }
        // The horizontal skew sign is inverted when reading from the slider
        // (see CropView+Rotation), so invert it back for display.
        slideDial.syncSkewValues(
            horizontal: -viewModel.horizontalSkewDegrees,
            vertical: viewModel.verticalSkewDegrees
        )
    }
    
    func computeSkewProjectionInputs(safetyInset: CGFloat) -> ([CGPoint], [CGPoint], CGPoint, CGPoint) {
        // Use the CENTER of the image container as the anchor, NOT the current
        // contentOffset. The sublayerTransform is applied uniformly to the
        // whole layer, so the compensating scale should not depend on where
        // the user has scrolled. Using contentOffset as anchor caused the
        // scale to change when switching skew axes after panning.
        let fr = imageContainer.frame
        let anchor = CGPoint(x: fr.midX, y: fr.midY)

        // Image container corners as displacements from the anchor (CW: TL, TR, BR, BL)
        let imageCornerDisplacements = [
            CGPoint(x: fr.minX - anchor.x, y: fr.minY - anchor.y),
            CGPoint(x: fr.maxX - anchor.x, y: fr.minY - anchor.y),
            CGPoint(x: fr.maxX - anchor.x, y: fr.maxY - anchor.y),
            CGPoint(x: fr.minX - anchor.x, y: fr.maxY - anchor.y)
        ]

        // Use the actual visible crop box corners (rotated into scroll view
        // local space) instead of the AABB. When the scroll view is rotated,
        // the AABB is larger than the actual visible area, which causes the
        // compensating scale to be unnecessarily large.
        let baseCropCorners = visibleCropCornersInScrollViewSpace
        // Apply safety inset: expand each corner outward from center by safetyInset.
        let visibleCornerDisplacements: [CGPoint]
        if safetyInset > 0 {
            visibleCornerDisplacements = baseCropCorners.map { corner in
                let len = sqrt(corner.x * corner.x + corner.y * corner.y)
                guard len > 1e-6 else { return corner }
                let scale = (len + safetyInset) / len
                return CGPoint(x: corner.x * scale, y: corner.y * scale)
            }
        } else {
            visibleCornerDisplacements = baseCropCorners
        }

        let visibleCenter = CGPoint(x: 0, y: 0)
        let visibleTopLeft = visibleCornerDisplacements.first ?? .zero
        return (imageCornerDisplacements, visibleCornerDisplacements, visibleCenter, visibleTopLeft)
    }
    
    /// Sets the horizontal skew degrees and refreshes the view
    func setHorizontalSkew(degrees: CGFloat) {
        let clamped = max(-PerspectiveTransformHelper.maxSkewDegrees,
                          min(PerspectiveTransformHelper.maxSkewDegrees, degrees))
        viewModel.horizontalSkewDegrees = clamped
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        checkImageStatusChanged()
    }
    
    /// Sets the vertical skew degrees and refreshes the view
    func setVerticalSkew(degrees: CGFloat) {
        let clamped = max(-PerspectiveTransformHelper.maxSkewDegrees,
                          min(PerspectiveTransformHelper.maxSkewDegrees, degrees))
        viewModel.verticalSkewDegrees = clamped
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        checkImageStatusChanged()
    }
}

// MARK: - Skew Inset Context & Helpers

extension CropView {
    /// Groups the shared geometric state needed by skew inset/offset calculations,
    /// avoiding repeated property lookups and keeping helper signatures clean.
    struct SkewInsetContext {
        let imageFrame: CGRect
        let boundsSize: CGSize
        let contentSize: CGSize
        let cropCorners: [CGPoint]
        let transform: CATransform3D
        
        var centerOffset: CGPoint {
            CGPoint(
                x: imageFrame.midX - boundsSize.width / 2,
                y: imageFrame.midY - boundsSize.height / 2
            )
        }
        
        /// Image corner displacements from a given anchor point.
        func imageCornerDisplacements(from anchor: CGPoint) -> [CGPoint] {
            [
                CGPoint(x: imageFrame.minX - anchor.x, y: imageFrame.minY - anchor.y),
                CGPoint(x: imageFrame.maxX - anchor.x, y: imageFrame.minY - anchor.y),
                CGPoint(x: imageFrame.maxX - anchor.x, y: imageFrame.maxY - anchor.y),
                CGPoint(x: imageFrame.minX - anchor.x, y: imageFrame.maxY - anchor.y)
            ]
        }
    }
    
    /// Directional shift distances used to compute insets and optimal offsets.
    struct SkewShifts {
        let top: CGFloat
        let left: CGFloat
        let bottom: CGFloat
        let right: CGFloat
        
        var centeredShiftX: CGFloat { (right - left) / 2 }
        var centeredShiftY: CGFloat { (bottom - top) / 2 }
    }
    
    // MARK: Validation
    
    /// Tests whether shifting the viewport by (shiftX, shiftY) from the image center
    /// keeps the crop box fully inside the projected (skewed) image quad.
    func isValidSkewPosition(shiftX: CGFloat, shiftY: CGFloat, context: SkewInsetContext) -> Bool {
        let anchor = CGPoint(
            x: context.centerOffset.x + shiftX + context.boundsSize.width / 2,
            y: context.centerOffset.y + shiftY + context.boundsSize.height / 2
        )
        let corners = context.imageCornerDisplacements(from: anchor)
        // Reject positions where any image corner is behind the camera
        // (w ≤ 0). At extreme skew angles a large shift can push corners
        // past the vanishing plane, flipping the projected polygon and
        // making the ray-casting containment test unreliable.
        guard PerspectiveTransformHelper.allProjectionsInFrontOfCamera(corners, through: context.transform) else {
            return false
        }
        let proj = corners.map {
            PerspectiveTransformHelper.projectDisplacement($0, through: context.transform)
        }
        return PerspectiveTransformHelper.allPointsInsideConvexPolygon(context.cropCorners, polygon: proj)
    }
    
    /// Tests whether a given contentOffset keeps the crop box inside the projected image quad.
    /// Used by `clampContentOffsetForSkewIfNeeded` for post-pan validation.
    func isValidSkewOffset(ox: CGFloat, oy: CGFloat, context: SkewInsetContext) -> Bool {
        let anchor = CGPoint(x: ox + context.boundsSize.width / 2,
                             y: oy + context.boundsSize.height / 2)
        let corners = context.imageCornerDisplacements(from: anchor)
        guard PerspectiveTransformHelper.allProjectionsInFrontOfCamera(corners, through: context.transform) else {
            return false
        }
        let proj = corners.map {
            PerspectiveTransformHelper.projectDisplacement($0, through: context.transform)
        }
        return PerspectiveTransformHelper.allPointsInsideConvexPolygon(context.cropCorners, polygon: proj)
    }
    
    // MARK: Shift Computation
    
    /// Binary-searches for the maximum valid shift distance along each cardinal direction.
    func computeMaxShifts(context: SkewInsetContext) -> SkewShifts {
        SkewShifts(
            top:    maxShiftInDirection(dirX: 0, dirY: -1, context: context),
            left:   maxShiftInDirection(dirX: -1, dirY: 0, context: context),
            bottom: maxShiftInDirection(dirX: 0, dirY: 1, context: context),
            right:  maxShiftInDirection(dirX: 1, dirY: 0, context: context)
        )
    }
    
    /// Binary-search for the max valid distance along a single direction.
    private func maxShiftInDirection(dirX: CGFloat, dirY: CGFloat, context: SkewInsetContext) -> CGFloat {
        // Use the image frame size so the search range covers the full
        // pannable area at any zoom level. Using only bounds would cap
        // the shift at the viewport size, rejecting valid positions when
        // zoomed in.
        let maxDist = max(context.imageFrame.width, context.imageFrame.height)
        var lo: CGFloat = 0
        var hi: CGFloat = maxDist
        for _ in 0..<16 {
            let mid = (lo + hi) / 2
            if isValidSkewPosition(shiftX: dirX * mid, shiftY: dirY * mid, context: context) {
                lo = mid
            } else {
                hi = mid
            }
        }
        return lo
    }
    
    // MARK: Inset Computation
    
    /// Converts shift distances into UIScrollView contentInset values.
    ///
    /// The shift represents displacement of contentOffset from centerOffset
    /// (the offset that centers the image in the viewport).
    /// These can be NEGATIVE when skew + rotation restricts the pan range
    /// below the scroll view's default.
    func computeSkewContentInset(shifts: SkewShifts, context: SkewInsetContext) -> UIEdgeInsets {
        let center = context.centerOffset
        let csW = context.contentSize.width
        let csH = context.contentSize.height
        let bW = context.boundsSize.width
        let bH = context.boundsSize.height
        
        return UIEdgeInsets(
            top:    shifts.top    - center.y,
            left:   shifts.left   - center.x,
            bottom: (center.y + shifts.bottom) - (csH - bH),
            right:  (center.x + shifts.right)  - (csW - bW)
        )
    }
    
    /// Fallback inset that locks the viewport to the image center.
    private func computeLockedCenterInset(context: SkewInsetContext) -> UIEdgeInsets {
        let center = context.centerOffset
        let bW = context.boundsSize.width
        let bH = context.boundsSize.height
        return UIEdgeInsets(
            top:    -center.y,
            left:   -center.x,
            bottom: center.y - (context.contentSize.height - bH),
            right:  center.x - (context.contentSize.width  - bW)
        )
    }
    
    // MARK: Optimal Offset (Two-Phase Positioning)
    
    /// Computes the optimal content offset for the current skew angle.
    ///
    /// **Phase 1** (|deg| ≤ ~10°, single-axis only): edge-to-edge — align the crop
    /// box edge toward the vanishing point flush with the skewed image edge.
    ///
    /// **Phase 2** (|deg| > ~10° or both axes active): vertex-to-edge inscribed —
    /// center the crop box in the valid range so vertices touch opposite edges.
    ///
    /// A smooth blend between 8°–12° avoids visual jumps at the threshold.
    func computeOptimalSkewOffset(
        hDeg: CGFloat,
        vDeg: CGFloat,
        shifts: SkewShifts,
        context: SkewInsetContext
    ) -> CGPoint {
        let centeredX = shifts.centeredShiftX
        let centeredY = shifts.centeredShiftY
        
        let optimalShiftX: CGFloat
        let optimalShiftY: CGFloat
        
        if cropBoxMatchesImageAspectRatio {
            let totalRadians = viewModel.getTotalRadians()
            
            // Rotation dampening: full dampening at ±10° of rotation.
            let rotationDampen = max(1 - abs(totalRadians) / (10 * .pi / 180), 0)
            
            // Cross-axis dampening: when the other axis has skew, the
            // combined perspective makes single-axis shift extremes unstable.
            let hActivity = min(abs(hDeg) / 3.0, 1.0)
            let vActivity = min(abs(vDeg) / 3.0, 1.0)
            
            optimalShiftY = computeEdgeToEdgeShift(
                deg: vDeg,
                positiveEdgeShift: -shifts.top,
                negativeEdgeShift: shifts.bottom,
                centeredShift: centeredY,
                rotationDampen: rotationDampen,
                crossAxisActivity: hActivity
            )
            
            optimalShiftX = computeEdgeToEdgeShift(
                deg: hDeg,
                positiveEdgeShift: shifts.right,
                negativeEdgeShift: -shifts.left,
                centeredShift: centeredX,
                rotationDampen: rotationDampen,
                crossAxisActivity: vActivity
            )
        } else {
            // Non-original aspect ratio: skip edge-to-edge, use centered.
            optimalShiftX = centeredX
            optimalShiftY = centeredY
        }
        
        let center = context.centerOffset
        return CGPoint(x: center.x + optimalShiftX, y: center.y + optimalShiftY)
    }
    
    /// Computes the blended shift for a single axis, transitioning from
    /// edge-to-edge alignment (small angles) to centered/inscribed (large angles).
    ///
    /// - Parameters:
    ///   - deg: Skew degrees on this axis (sign determines direction).
    ///   - positiveEdgeShift: Shift value when deg > 0 (toward vanishing edge).
    ///   - negativeEdgeShift: Shift value when deg < 0 (toward vanishing edge).
    ///   - centeredShift: Centered (inscribed) shift for this axis.
    ///   - rotationDampen: Dampening factor from scroll view rotation [0..1].
    ///   - crossAxisActivity: How active the other axis is [0..1], used for dampening.
    private func computeEdgeToEdgeShift(
        deg: CGFloat,
        positiveEdgeShift: CGFloat,
        negativeEdgeShift: CGFloat,
        centeredShift: CGFloat,
        rotationDampen: CGFloat,
        crossAxisActivity: CGFloat
    ) -> CGFloat {
        let transitionStart: CGFloat = 8.0
        let transitionEnd: CGFloat = 12.0
        
        let dampen = rotationDampen * (1 - crossAxisActivity)
        
        let rawEdgeAligned: CGFloat
        if deg > 0 {
            rawEdgeAligned = positiveEdgeShift
        } else if deg < 0 {
            rawEdgeAligned = negativeEdgeShift
        } else {
            rawEdgeAligned = centeredShift
        }
        
        let edgeAligned = centeredShift + (rawEdgeAligned - centeredShift) * dampen
        let absDeg = abs(deg)
        let blend = min(max((absDeg - transitionStart) / (transitionEnd - transitionStart), 0), 1)
        return edgeAligned + (centeredShift - edgeAligned) * blend
    }
    
    // MARK: Offset Application
    
    /// Applies the computed optimal offset to the scroll view, preserving the
    /// user's manual panning by applying only the delta from the previous optimal.
    private func applySkewContentOffset(
        optimalOffset: CGPoint,
        inset: UIEdgeInsets,
        context: SkewInsetContext
    ) {
        guard optimalOffset.x.isFinite && optimalOffset.y.isFinite else { return }
        
        let bW = context.boundsSize.width
        let bH = context.boundsSize.height
        let minX = -inset.left
        let maxX = context.contentSize.width - bW + inset.right
        let minY = -inset.top
        let maxY = context.contentSize.height - bH + inset.bottom
        
        let isZoomedIn = cropWorkbenchView.zoomScale > cropWorkbenchView.minimumZoomScale + 0.01
        
        if let prevOptimal = skewState.previousOptimalOffset {
            // Subsequent skew change: apply the delta between the new
            // and previous optimal positions to the user's current
            // offset. This preserves any manual panning the user did
            // between skew adjustments. When zoomed in the delta is
            // suppressed to keep the view stable.
            let current = cropWorkbenchView.contentOffset
            if !isZoomedIn {
                let deltaX = optimalOffset.x - prevOptimal.x
                let deltaY = optimalOffset.y - prevOptimal.y
                cropWorkbenchView.contentOffset = CGPoint(
                    x: min(max(current.x + deltaX, minX), maxX),
                    y: min(max(current.y + deltaY, minY), maxY)
                )
            } else {
                cropWorkbenchView.contentOffset = CGPoint(
                    x: min(max(current.x, minX), maxX),
                    y: min(max(current.y, minY), maxY)
                )
            }
        } else {
            // First skew change from zero: jump directly to optimal
            // for strict edge-to-edge alignment.
            cropWorkbenchView.contentOffset = optimalOffset
        }
        
        skewState.previousOptimalOffset = optimalOffset
    }
    
    // MARK: Scale Boost
    
    /// Edge-to-edge scale boost: at small angles, the inscribed-fit scale leaves
    /// no room for content offset shifting. This adds a small extra factor so
    /// the projected image is slightly larger than the minimum, giving
    /// `updateContentInsetForSkew` headroom to position the crop box flush
    /// against the vanishing-point edge.
    ///
    /// The boost ramps up linearly with |deg|, peaks around 8-10°, then fades
    /// to 0 at 12° where the vertex-to-edge inscribed behavior takes over.
    /// Skipped when the crop box has a different aspect ratio from the image.
    private func computeEdgeToEdgeScaleBoost(hDeg: CGFloat, vDeg: CGFloat) -> CGFloat {
        guard cropBoxMatchesImageAspectRatio else { return 1.0 }
        
        let transitionEnd: CGFloat = 12.0
        let absH = abs(hDeg)
        let absV = abs(vDeg)
        let hActivity = min(absH / 3.0, 1.0)
        let vActivity = min(absV / 3.0, 1.0)
        
        // Each axis's boost is dampened by the other axis's activity.
        let hEdgeFade = max(1 - absH / transitionEnd, 0) * (1 - vActivity)
        let vEdgeFade = max(1 - absV / transitionEnd, 0) * (1 - hActivity)
        
        // Scale the boost by how much skew there is (normalized to 0-1
        // within the edge-to-edge range).
        let hBoostIntensity = min(absH / 10.0, 1.0) * hEdgeFade
        let vBoostIntensity = min(absV / 10.0, 1.0) * vEdgeFade
        return 1.0 + 0.04 * max(hBoostIntensity, vBoostIntensity)
    }
    
    // MARK: State Reset
    
    private func resetSkewInsetState() {
        cropWorkbenchView.contentInset = .zero
        skewState.previousInset = .zero
        skewState.previousOptimalOffset = nil
    }
}
