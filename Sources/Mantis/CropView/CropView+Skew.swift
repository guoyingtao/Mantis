//
//  CropView+Skew.swift
//  Mantis
//
//  Extracted from CropView.swift
//

import UIKit

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
        let totalRadians = viewModel.getTotalRadians()
        let cosR = cos(totalRadians)
        let sinR = sin(totalRadians)

        // Crop box corners (±halfWidth, ±halfHeight) rotated by -r into scroll view space.
        // Rotation by -r: x' = cx*cos(r) + cy*sin(r), y' = -cx*sin(r) + cy*cos(r)
        let halfWidth = cropW / 2
        let halfHeight = cropH / 2
        return [
            CGPoint(x: -halfWidth * cosR - halfHeight * sinR, y: halfWidth * sinR - halfHeight * cosR),
            CGPoint(x: halfWidth * cosR - halfHeight * sinR, y: -halfWidth * sinR - halfHeight * cosR),
            CGPoint(x: halfWidth * cosR + halfHeight * sinR, y: -halfWidth * sinR + halfHeight * cosR),
            CGPoint(x: -halfWidth * cosR + halfHeight * sinR, y: halfWidth * sinR + halfHeight * cosR)
        ]
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
            previousSkewScale = 1.0
            previousSkewInset = .zero
            previousSkewOptimalOffset = nil
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
            
            // Edge-to-edge scale boost: at small angles, the inscribed-fit
            // scale leaves no room for content offset shifting. Add a small
            // extra factor so the projected image is slightly larger than the
            // minimum, giving updateContentInsetForSkew headroom to position
            // the crop box flush against the vanishing-point edge.
            //
            // The boost ramps up linearly with |deg| (more skew = more offset
            // needed), peaks around 8-10°, then fades to 0 at 12° where the
            // vertex-to-edge inscribed behavior takes over.
            let transitionEnd: CGFloat = 12.0
            let absH = abs(hDeg)
            let absV = abs(vDeg)
            let hActivity = min(absH / 3.0, 1.0)
            let vActivity = min(absV / 3.0, 1.0)
            
            // Each axis's boost is dampened by the other axis's activity
            // (same logic as in updateContentInsetForSkew).
            let hEdgeFade = max(1 - absH / transitionEnd, 0) * (1 - vActivity)
            let vEdgeFade = max(1 - absV / transitionEnd, 0) * (1 - hActivity)
            
            // Scale the boost by how much skew there is (normalized to 0-1
            // within the edge-to-edge range).
            let hBoostIntensity = min(absH / 10.0, 1.0) * hEdgeFade
            let vBoostIntensity = min(absV / 10.0, 1.0) * vEdgeFade
            let edgeBoost = 1.0 + 0.04 * max(hBoostIntensity, vBoostIntensity)
            
            var finalScale = rawScale * edgeBoost
            
            // Guard against degenerate values
            if !finalScale.isFinite || finalScale < 1.0 {
                finalScale = max(previousSkewScale, 1.0)
            }
            
            previousSkewScale = finalScale
            
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
            cropWorkbenchView.contentInset = .zero
            previousSkewInset = .zero
            previousSkewOptimalOffset = nil
            return
        }

        let transform = cropWorkbenchView.layer.sublayerTransform
        guard !CATransform3DIsIdentity(transform) else {
            cropWorkbenchView.contentInset = .zero
            previousSkewInset = .zero
            previousSkewOptimalOffset = nil
            return
        }

        let fr = imageContainer.frame
        let boundsW = cropWorkbenchView.bounds.width
        let boundsH = cropWorkbenchView.bounds.height
        // Use the actual visible crop box corners (rotated into scroll view
        // local space) instead of the scroll view's axis-aligned bounding box.
        // The AABB grows with rotation (up to ~41% larger at 45°), making
        // containment tests over-conservative and rejecting valid pan positions.
        let cropCorners = visibleCropCornersInScrollViewSpace

        // Use the CENTER of the image as the anchor, consistent with
        // computeSkewProjectionInputs. This makes insets independent of the
        // current pan position, preventing abrupt inset redistribution when
        // the perspective axis changes.
        let centerOffset = CGPoint(
            x: fr.midX - boundsW / 2,
            y: fr.midY - boundsH / 2
        )

        func isValidShift(_ shiftX: CGFloat, _ shiftY: CGFloat) -> Bool {
            let testAnchor = CGPoint(
                x: centerOffset.x + shiftX + boundsW / 2,
                y: centerOffset.y + shiftY + boundsH / 2
            )
            let testCorners = [
                CGPoint(x: fr.minX - testAnchor.x, y: fr.minY - testAnchor.y),
                CGPoint(x: fr.maxX - testAnchor.x, y: fr.minY - testAnchor.y),
                CGPoint(x: fr.maxX - testAnchor.x, y: fr.maxY - testAnchor.y),
                CGPoint(x: fr.minX - testAnchor.x, y: fr.maxY - testAnchor.y)
            ]
            // Reject positions where any image corner is behind the camera
            // (w ≤ 0). At extreme skew angles a large shift can push corners
            // past the vanishing plane, flipping the projected polygon and
            // making the ray-casting containment test unreliable.
            guard PerspectiveTransformHelper.allProjectionsInFrontOfCamera(testCorners, through: transform) else {
                return false
            }
            let proj = testCorners.map {
                PerspectiveTransformHelper.projectDisplacement($0, through: transform)
            }
            return PerspectiveTransformHelper.allPointsInsideConvexPolygon(cropCorners, polygon: proj)
        }

        // Binary-search for the max valid distance along a given direction.
        func maxShift(dirX: CGFloat, dirY: CGFloat) -> CGFloat {
            // Use the image frame size so the search range covers the full
            // pannable area at any zoom level. Using only bounds would cap
            // the shift at the viewport size, rejecting valid positions when
            // zoomed in.
            let maxDist = max(fr.width, fr.height)
            var lo: CGFloat = 0
            var hi: CGFloat = maxDist
            for _ in 0..<16 {
                let mid = (lo + hi) / 2
                if isValidShift(dirX * mid, dirY * mid) {
                    lo = mid
                } else {
                    hi = mid
                }
            }
            return lo
        }

        let newInset: UIEdgeInsets

        if isValidShift(0, 0) {
            // Get the maximum valid shift distance along each axis.
            let shiftTop    = maxShift(dirX: 0, dirY: -1)
            let shiftLeft   = maxShift(dirX: -1, dirY: 0)
            let shiftBottom = maxShift(dirX: 0, dirY: 1)
            let shiftRight  = maxShift(dirX: 1, dirY: 0)

            // Convert shifts (relative to image center) into UIScrollView
            // contentInset values.
            //
            // The shift represents displacement of contentOffset from
            // centerOffset (the offset that centers the image in the viewport).
            //
            //   desired min contentOffset = centerOffset - shiftLeft
            //   desired max contentOffset = centerOffset + shiftRight
            //
            // UIScrollView's offset range with insets:
            //   min = -inset.left
            //   max = contentSize - bounds + inset.right
            //
            // Solving:
            //   inset.left  = shiftLeft  - centerOffset.x
            //   inset.right = (centerOffset.x + shiftRight) - (contentSize.w - boundsW)
            //   inset.top   = shiftTop   - centerOffset.y
            //   inset.bottom= (centerOffset.y + shiftBottom) - (contentSize.h - boundsH)
            //
            // These can be NEGATIVE when skew + rotation restricts the pan
            // range below the scroll view's default.
            let csW = cropWorkbenchView.contentSize.width
            let csH = cropWorkbenchView.contentSize.height

            newInset = UIEdgeInsets(
                top:    shiftTop    - centerOffset.y,
                left:   shiftLeft   - centerOffset.x,
                bottom: (centerOffset.y + shiftBottom) - (csH - boundsH),
                right:  (centerOffset.x + shiftRight)  - (csW - boundsW)
            )
            
            // --- Two-phase content offset positioning for skew ---
            // Phase 1 (|deg| ≤ ~10°, single-axis only): edge-to-edge — align
            // the crop box edge toward the vanishing point flush with the
            // skewed image edge.
            // Phase 2 (|deg| > ~10° or both axes active): vertex-to-edge
            // inscribed — center the crop box in the valid range so vertices
            // touch opposite edges.
            // A smooth blend between 8°–12° avoids visual jumps at the threshold.
            //
            // Dampening factors:
            // - Rotation: edge-to-edge is axis-aligned; when the scroll view
            //   is rotated the axes no longer match the visual edges.
            // - Cross-axis: when one axis already has skew, the other axis's
            //   edge-to-edge shift can change abruptly as the combined
            //   transform changes. Dampen each axis by the other's activity.
            let centeredShiftX = (shiftRight - shiftLeft) / 2
            let centeredShiftY = (shiftBottom - shiftTop) / 2
            
            let totalRadians = viewModel.getTotalRadians()
            
            // Rotation dampening: full dampening at ±10° of rotation.
            let rotationDampen = max(1 - abs(totalRadians) / (10 * .pi / 180), 0)
            
            // Cross-axis dampening: when the other axis has skew, the
            // combined perspective makes single-axis shift extremes unstable.
            // Dampen each axis's edge-to-edge by how much the other axis is active.
            let hActivity = min(abs(hDeg) / 3.0, 1.0)  // ramp up quickly
            let vActivity = min(abs(vDeg) / 3.0, 1.0)
            
            let transitionStart: CGFloat = 8.0
            let transitionEnd: CGFloat = 12.0
            
            // Vertical skew: edge-to-edge on Y axis
            let vDampen = rotationDampen * (1 - hActivity)
            let rawEdgeAlignedShiftY: CGFloat
            if vDeg > 0 {
                // Top narrows → push crop box toward top edge
                rawEdgeAlignedShiftY = -shiftTop
            } else if vDeg < 0 {
                // Bottom narrows → push crop box toward bottom edge
                rawEdgeAlignedShiftY = shiftBottom
            } else {
                rawEdgeAlignedShiftY = centeredShiftY
            }
            let edgeAlignedShiftY = centeredShiftY + (rawEdgeAlignedShiftY - centeredShiftY) * vDampen
            let absV = abs(vDeg)
            let blendV = min(max((absV - transitionStart) / (transitionEnd - transitionStart), 0), 1)
            let optimalShiftY = edgeAlignedShiftY + (centeredShiftY - edgeAlignedShiftY) * blendV
            
            // Horizontal skew: edge-to-edge on X axis
            let hDampen = rotationDampen * (1 - vActivity)
            let rawEdgeAlignedShiftX: CGFloat
            if hDeg > 0 {
                // Right recedes → push crop box toward right edge
                rawEdgeAlignedShiftX = shiftRight
            } else if hDeg < 0 {
                // Left recedes → push crop box toward left edge
                rawEdgeAlignedShiftX = -shiftLeft
            } else {
                rawEdgeAlignedShiftX = centeredShiftX
            }
            let edgeAlignedShiftX = centeredShiftX + (rawEdgeAlignedShiftX - centeredShiftX) * hDampen
            let absH = abs(hDeg)
            let blendH = min(max((absH - transitionStart) / (transitionEnd - transitionStart), 0), 1)
            let optimalShiftX = edgeAlignedShiftX + (centeredShiftX - edgeAlignedShiftX) * blendH
            let optimalX = centerOffset.x + optimalShiftX
            let optimalY = centerOffset.y + optimalShiftY
            
            if optimalX.isFinite && optimalY.isFinite {
                let newOptimal = CGPoint(x: optimalX, y: optimalY)
                
                // Valid content offset range defined by the new insets.
                let minX = -newInset.left
                let maxX = cropWorkbenchView.contentSize.width - boundsW + newInset.right
                let minY = -newInset.top
                let maxY = cropWorkbenchView.contentSize.height - boundsH + newInset.bottom
                
                if let prevOptimal = previousSkewOptimalOffset {
                    // Delta-based update: shift the current position by how
                    // much the optimal position moved, preserving the user's
                    // zoom/pan offset instead of jumping to the absolute optimal.
                    let deltaX = newOptimal.x - prevOptimal.x
                    let deltaY = newOptimal.y - prevOptimal.y
                    let current = cropWorkbenchView.contentOffset
                    let targetX = current.x + deltaX
                    let targetY = current.y + deltaY
                    
                    cropWorkbenchView.contentOffset = CGPoint(
                        x: min(max(targetX, minX), maxX),
                        y: min(max(targetY, minY), maxY)
                    )
                } else {
                    // First skew change from zero — don't jump to the optimal
                    // position; just clamp the current offset to the valid range.
                    // This preserves the user's zoom/pan position.
                    let current = cropWorkbenchView.contentOffset
                    cropWorkbenchView.contentOffset = CGPoint(
                        x: min(max(current.x, minX), maxX),
                        y: min(max(current.y, minY), maxY)
                    )
                }
                
                previousSkewOptimalOffset = newOptimal
            }
        } else {
            // Center-based test fails — the projected image at the center
            // anchor is too small to cover the crop box. Lock to center.
            newInset = UIEdgeInsets(
                top:    -centerOffset.y,
                left:   -centerOffset.x,
                bottom: centerOffset.y - (cropWorkbenchView.contentSize.height - boundsH),
                right:  centerOffset.x - (cropWorkbenchView.contentSize.width  - boundsW)
            )
        }

        // Guard against non-finite inset values that can arise from
        // degenerate perspective projections at extreme zoom levels.
        guard newInset.top.isFinite && newInset.left.isFinite
                && newInset.bottom.isFinite && newInset.right.isFinite else {
            return
        }

        previousSkewInset = newInset
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

        let fr = imageContainer.frame
        let boundsW = cropWorkbenchView.bounds.width
        let boundsH = cropWorkbenchView.bounds.height
        // Use actual visible crop corners instead of AABB (see updateContentInsetForSkew).
        let cropCorners = visibleCropCornersInScrollViewSpace

        let curOffset = cropWorkbenchView.contentOffset

        // First, clamp to inset bounds (standard scroll view range).
        let inset = cropWorkbenchView.contentInset
        let maxOffsetX = cropWorkbenchView.contentSize.width - boundsW + inset.right
        let maxOffsetY = cropWorkbenchView.contentSize.height - boundsH + inset.bottom
        var targetX = max(-inset.left, min(maxOffsetX, curOffset.x))
        var targetY = max(-inset.top, min(maxOffsetY, curOffset.y))

        // Then, do a perspective containment test at the clamped position.
        // If the position is invalid (corner of the inset rect outside the
        // projected image), pull back toward the image center.
        let centerOffset = CGPoint(
            x: fr.midX - boundsW / 2,
            y: fr.midY - boundsH / 2
        )

        func isValidOffset(_ ox: CGFloat, _ oy: CGFloat) -> Bool {
            let anchor = CGPoint(x: ox + boundsW / 2, y: oy + boundsH / 2)
            let testCorners = [
                CGPoint(x: fr.minX - anchor.x, y: fr.minY - anchor.y),
                CGPoint(x: fr.maxX - anchor.x, y: fr.minY - anchor.y),
                CGPoint(x: fr.maxX - anchor.x, y: fr.maxY - anchor.y),
                CGPoint(x: fr.minX - anchor.x, y: fr.maxY - anchor.y)
            ]
            guard PerspectiveTransformHelper.allProjectionsInFrontOfCamera(testCorners, through: transform) else {
                return false
            }
            let proj = testCorners.map {
                PerspectiveTransformHelper.projectDisplacement($0, through: transform)
            }
            return PerspectiveTransformHelper.allPointsInsideConvexPolygon(cropCorners, polygon: proj)
        }

        if !isValidOffset(targetX, targetY) {
            if isValidOffset(centerOffset.x, centerOffset.y) {
                // Binary-search along the line from current position toward center
                // to find the nearest valid point.
                var lo: CGFloat = 0  // center
                var hi: CGFloat = 1  // current position
                for _ in 0..<16 {
                    let mid = (lo + hi) / 2
                    let testX = centerOffset.x + (targetX - centerOffset.x) * mid
                    let testY = centerOffset.y + (targetY - centerOffset.y) * mid
                    if isValidOffset(testX, testY) {
                        lo = mid
                    } else {
                        hi = mid
                    }
                }
                targetX = centerOffset.x + (targetX - centerOffset.x) * lo
                targetY = centerOffset.y + (targetY - centerOffset.y) * lo
            } else {
                // At extreme skew angles the polygon containment test can
                // reject even the image center due to floating-point limits.
                // Fall back to the center — it is geometrically the safest
                // position and keeps the crop box within the image.
                targetX = centerOffset.x
                targetY = centerOffset.y
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
