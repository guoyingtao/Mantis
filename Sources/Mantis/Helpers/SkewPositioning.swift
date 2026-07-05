//
//  SkewPositioning.swift
//  Mantis
//
//  Pure, UIKit-free geometry backing the perspective-skew crop preview.
//
//  These functions were extracted verbatim from `CropView+Skew.swift`. They
//  take plain value types (`SkewInsetContext`, `SkewShifts`, CGFloats) and
//  return plain values — no view, view-model, or scroll-view state — so their
//  behavior can be pinned by unit tests. That matters because the live preview
//  keeps three sources of truth (view-model angle, sublayerTransform,
//  contentInset) in manual sync, making regressions in this math easy to
//  introduce and hard to spot visually.
//

import CoreGraphics
import UIKit

/// Tuning constants for the perspective-skew positioning math. Collecting the
/// transition angles, dampening ramps, and epsilons here — instead of scattering
/// them as inline literals — makes each value named, documented, and adjustable
/// in one place.
enum SkewTuning {
    /// Angle (°) at which edge-to-edge alignment starts blending toward the
    /// vertex-to-edge inscribed fit.
    static let transitionStartDegrees: CGFloat = 8.0
    /// Angle (°) at which the blend to the inscribed fit completes.
    static let transitionEndDegrees: CGFloat = 12.0
    /// Skew degrees over which one axis ramps to "fully active"; used to dampen
    /// the other axis's edge-to-edge shift and scale boost.
    static let axisActivityRampDegrees: CGFloat = 3.0
    /// Skew degrees over which the small-angle scale boost ramps to full intensity.
    static let scaleBoostRampDegrees: CGFloat = 10.0
    /// Peak extra scale added at small angles so the projected image has headroom
    /// for edge-to-edge content-offset positioning.
    static let maxScaleBoost: CGFloat = 0.04
    /// Rotation (°) at which edge-to-edge dampening reaches full strength.
    static let rotationDampenDegrees: CGFloat = 10.0
    /// Relative tolerance for treating the crop box and image aspect ratios as equal.
    static let aspectRatioMatchTolerance: CGFloat = 0.05
    /// Safety inset (pt) guarding against sub-pixel gaps at the crop box edge.
    static let cropBoxSafetyInset: CGFloat = 2
    /// Iterations for the shift / offset binary searches.
    static let binarySearchIterations = 16
    /// Duration (s) of the pull-back animation after an invalid pan.
    static let clampAnimationDuration: TimeInterval = 0.15
    /// Zoom delta above the minimum scale that counts as "zoomed in".
    static let zoomedInEpsilon: CGFloat = 0.01
    /// Minimum corner distance (pt) below which safety-inset scaling is skipped,
    /// avoiding division by a near-zero length.
    static let minCornerLength: CGFloat = 1e-6
}

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

/// Pure geometry for positioning the crop box within the projected (skewed)
/// image quad. Stateless — every input arrives via parameters.
enum SkewPositioning {

    // MARK: Validation

    /// Tests whether shifting the viewport by (shiftX, shiftY) from the image center
    /// keeps the crop box fully inside the projected (skewed) image quad.
    static func isCropBoxInside(shiftX: CGFloat, shiftY: CGFloat, context: SkewInsetContext) -> Bool {
        let anchor = CGPoint(
            x: context.centerOffset.x + shiftX + context.boundsSize.width / 2,
            y: context.centerOffset.y + shiftY + context.boundsSize.height / 2
        )
        return isCropBoxInside(anchor: anchor, context: context)
    }

    /// Tests whether a given contentOffset keeps the crop box inside the projected image quad.
    /// Used by `clampContentOffsetForSkewIfNeeded` for post-pan validation.
    static func isCropBoxInside(offsetX: CGFloat, offsetY: CGFloat, context: SkewInsetContext) -> Bool {
        let anchor = CGPoint(x: offsetX + context.boundsSize.width / 2,
                             y: offsetY + context.boundsSize.height / 2)
        return isCropBoxInside(anchor: anchor, context: context)
    }

    /// Shared containment test: projects the image corners (as displacements
    /// from `anchor`) through the perspective transform and checks the crop box
    /// lies inside the resulting quad.
    private static func isCropBoxInside(anchor: CGPoint, context: SkewInsetContext) -> Bool {
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

    // MARK: Shift Computation

    /// Binary-searches for the maximum valid shift distance along each cardinal direction.
    static func maxShifts(context: SkewInsetContext) -> SkewShifts {
        SkewShifts(
            top: maxShift(dirX: 0, dirY: -1, context: context),
            left: maxShift(dirX: -1, dirY: 0, context: context),
            bottom: maxShift(dirX: 0, dirY: 1, context: context),
            right: maxShift(dirX: 1, dirY: 0, context: context)
        )
    }

    /// Binary-search for the max valid distance along a single direction.
    static func maxShift(dirX: CGFloat, dirY: CGFloat, context: SkewInsetContext) -> CGFloat {
        // Use the image frame size so the search range covers the full
        // pannable area at any zoom level. Using only bounds would cap
        // the shift at the viewport size, rejecting valid positions when
        // zoomed in.
        let maxDist = max(context.imageFrame.width, context.imageFrame.height)
        var lowerBound: CGFloat = 0
        var upperBound: CGFloat = maxDist
        for _ in 0..<SkewTuning.binarySearchIterations {
            let mid = (lowerBound + upperBound) / 2
            if isCropBoxInside(shiftX: dirX * mid, shiftY: dirY * mid, context: context) {
                lowerBound = mid
            } else {
                upperBound = mid
            }
        }
        return lowerBound
    }

    // MARK: Inset Computation

    /// Converts shift distances into UIScrollView contentInset values.
    ///
    /// The shift represents displacement of contentOffset from centerOffset
    /// (the offset that centers the image in the viewport).
    /// These can be NEGATIVE when skew + rotation restricts the pan range
    /// below the scroll view's default.
    static func contentInset(shifts: SkewShifts, context: SkewInsetContext) -> UIEdgeInsets {
        let center = context.centerOffset
        let contentWidth = context.contentSize.width
        let contentHeight = context.contentSize.height
        let boundsWidth = context.boundsSize.width
        let boundsHeight = context.boundsSize.height

        return UIEdgeInsets(
            top: shifts.top - center.y,
            left: shifts.left - center.x,
            bottom: (center.y + shifts.bottom) - (contentHeight - boundsHeight),
            right: (center.x + shifts.right) - (contentWidth - boundsWidth)
        )
    }

    /// Fallback inset that locks the viewport to the image center.
    static func lockedCenterInset(context: SkewInsetContext) -> UIEdgeInsets {
        let center = context.centerOffset
        let boundsWidth = context.boundsSize.width
        let boundsHeight = context.boundsSize.height
        return UIEdgeInsets(
            top: -center.y,
            left: -center.x,
            bottom: center.y - (context.contentSize.height - boundsHeight),
            right: center.x - (context.contentSize.width - boundsWidth)
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
    ///
    /// - Parameters:
    ///   - matchesAspectRatio: Whether the crop box matches the image aspect
    ///     ratio; when false the edge-to-edge phase is skipped (centered only).
    ///   - totalRadians: The scroll view's total rotation, used for dampening.
    static func optimalOffset(
        hDeg: CGFloat,
        vDeg: CGFloat,
        shifts: SkewShifts,
        context: SkewInsetContext,
        matchesAspectRatio: Bool,
        totalRadians: CGFloat
    ) -> CGPoint {
        let centeredX = shifts.centeredShiftX
        let centeredY = shifts.centeredShiftY

        let optimalShiftX: CGFloat
        let optimalShiftY: CGFloat

        if matchesAspectRatio {
            // Rotation dampening: full dampening at ±10° of rotation.
            let rotationDampen = max(1 - abs(totalRadians) / (SkewTuning.rotationDampenDegrees * .pi / 180), 0)

            // Cross-axis dampening: when the other axis has skew, the
            // combined perspective makes single-axis shift extremes unstable.
            let hActivity = min(abs(hDeg) / SkewTuning.axisActivityRampDegrees, 1.0)
            let vActivity = min(abs(vDeg) / SkewTuning.axisActivityRampDegrees, 1.0)

            optimalShiftY = edgeToEdgeShift(
                deg: vDeg,
                positiveEdgeShift: -shifts.top,
                negativeEdgeShift: shifts.bottom,
                centeredShift: centeredY,
                rotationDampen: rotationDampen,
                crossAxisActivity: hActivity
            )

            optimalShiftX = edgeToEdgeShift(
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
    static func edgeToEdgeShift(
        deg: CGFloat,
        positiveEdgeShift: CGFloat,
        negativeEdgeShift: CGFloat,
        centeredShift: CGFloat,
        rotationDampen: CGFloat,
        crossAxisActivity: CGFloat
    ) -> CGFloat {
        let transitionStart = SkewTuning.transitionStartDegrees
        let transitionEnd = SkewTuning.transitionEndDegrees

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

    // MARK: Scale Boost

    /// Edge-to-edge scale boost: at small angles, the inscribed-fit scale leaves
    /// no room for content offset shifting. This adds a small extra factor so
    /// the projected image is slightly larger than the minimum, giving
    /// `updateContentInsetForSkew` headroom to position the crop box flush
    /// against the vanishing-point edge.
    ///
    /// The boost ramps up linearly with |deg|, peaks around 8-10°, then fades
    /// to 0 at 12° where the vertex-to-edge inscribed behavior takes over.
    ///
    /// Callers should skip this (use 1.0) when the crop box has a different
    /// aspect ratio from the image.
    static func edgeToEdgeScaleBoost(hDeg: CGFloat, vDeg: CGFloat) -> CGFloat {
        let transitionEnd = SkewTuning.transitionEndDegrees
        let absH = abs(hDeg)
        let absV = abs(vDeg)
        let hActivity = min(absH / SkewTuning.axisActivityRampDegrees, 1.0)
        let vActivity = min(absV / SkewTuning.axisActivityRampDegrees, 1.0)

        // Each axis's boost is dampened by the other axis's activity.
        let hEdgeFade = max(1 - absH / transitionEnd, 0) * (1 - vActivity)
        let vEdgeFade = max(1 - absV / transitionEnd, 0) * (1 - hActivity)

        // Scale the boost by how much skew there is (normalized to 0-1
        // within the edge-to-edge range).
        let hBoostIntensity = min(absH / SkewTuning.scaleBoostRampDegrees, 1.0) * hEdgeFade
        let vBoostIntensity = min(absV / SkewTuning.scaleBoostRampDegrees, 1.0) * vEdgeFade
        return 1.0 + SkewTuning.maxScaleBoost * max(hBoostIntensity, vBoostIntensity)
    }
}
