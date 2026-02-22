//
//  PerspectiveTransformHelper.swift
//  Mantis
//
//  Helper for computing CATransform3D perspective skew transforms
//  and CIPerspectiveTransform parameters for image export.
//

import UIKit

// swiftlint:disable all
/// Represents the type of rotation/skew adjustment the user is performing
public enum RotationAdjustmentType: Int, CaseIterable {
    case straighten = 0
    case horizontalSkew = 1
    case verticalSkew = 2
    
    var localizedTitle: String {
        switch self {
        case .straighten:
            return LocalizedHelper.getString("Mantis.Straighten", value: "Straighten")
        case .horizontalSkew:
            return LocalizedHelper.getString("Mantis.Horizontal", value: "Horizontal")
        case .verticalSkew:
            return LocalizedHelper.getString("Mantis.Vertical", value: "Vertical")
        }
    }
}

struct PerspectiveTransformHelper {
    /// Maximum skew angle in degrees
    static let maxSkewDegrees: CGFloat = 30.0
    
    /// The perspective depth factor (m34). Smaller absolute values = more dramatic perspective.
    static let perspectiveDepth: CGFloat = -1.0 / 500.0
    
    /// The threshold angle (in degrees) beyond which we also translate the rotation axis
    /// to mimic Apple Photos app behavior
    static let translateThresholdDegrees: CGFloat = 10.0
    
    // MARK: - CATransform3D for real-time preview
    
    /// Computes a CATransform3D for horizontal skew (rotation around Y-axis).
    /// - Parameter degrees: The skew angle in degrees (negative = left, positive = right)
    /// - Returns: A CATransform3D with perspective
    static func horizontalSkewTransform3D(degrees: CGFloat) -> CATransform3D {
        let radians = degrees * .pi / 180.0
        var transform = CATransform3DIdentity
        transform.m34 = perspectiveDepth
        transform = CATransform3DRotate(transform, radians, 0, 1, 0)
        
        // When angle exceeds threshold, translate to simulate Apple Photos behavior
        if abs(degrees) > translateThresholdDegrees {
            let excessDegrees = abs(degrees) - translateThresholdDegrees
            let translateFactor = excessDegrees * 2.0
            let direction: CGFloat = degrees > 0 ? -1 : 1
            transform = CATransform3DTranslate(transform, direction * translateFactor, 0, 0)
        }
        
        return transform
    }
    
    /// Computes a CATransform3D for vertical skew (rotation around X-axis).
    /// - Parameter degrees: The skew angle in degrees (negative = up, positive = down)
    /// - Returns: A CATransform3D with perspective
    static func verticalSkewTransform3D(degrees: CGFloat) -> CATransform3D {
        let radians = degrees * .pi / 180.0
        var transform = CATransform3DIdentity
        transform.m34 = perspectiveDepth
        transform = CATransform3DRotate(transform, radians, 1, 0, 0)
        
        // When angle exceeds threshold, translate to simulate Apple Photos behavior
        if abs(degrees) > translateThresholdDegrees {
            let excessDegrees = abs(degrees) - translateThresholdDegrees
            let translateFactor = excessDegrees * 2.0
            let direction: CGFloat = degrees > 0 ? -1 : 1
            transform = CATransform3DTranslate(transform, 0, direction * translateFactor, 0)
        }
        
        return transform
    }
    
    /// Combines horizontal and vertical skew into a single CATransform3D.
    /// - Parameters:
    ///   - horizontalDegrees: Horizontal skew angle
    ///   - verticalDegrees: Vertical skew angle
    ///   - zoomScale: The current scroll view zoom scale. The perspective depth
    ///     is divided by this value so that the vanishing-plane distance grows
    ///     with zoom, preventing image corners from crossing behind the camera
    ///     at high zoom levels (which would produce NaN layer positions).
    static func combinedSkewTransform3D(horizontalDegrees: CGFloat,
                                        verticalDegrees: CGFloat,
                                        zoomScale: CGFloat = 1) -> CATransform3D {
        if horizontalDegrees == 0 && verticalDegrees == 0 {
            return CATransform3DIdentity
        }
        
        var effectiveZoom = max(zoomScale, 1)
        
        // When both axes have significant skew, the combined rotation
        // compounds perspective distortion far more than either axis alone.
        // This pushes image corners closer to the camera plane (w → 0),
        // shrinking the projected quad and severely restricting panning.
        // Reduce the perspective intensity proportionally to the combined
        // skew magnitude — the same effect as the user zooming in slightly.
        let hFraction = min(abs(horizontalDegrees) / maxSkewDegrees, 1)
        let vFraction = min(abs(verticalDegrees) / maxSkewDegrees, 1)
        let combinedIntensity = hFraction * vFraction
        if combinedIntensity > 0 {
            // At max combined skew (both 30°), boost effective zoom by ~30%
            effectiveZoom *= (1 + 0.3 * combinedIntensity)
        }
        
        var transform = CATransform3DIdentity
        transform.m34 = perspectiveDepth / effectiveZoom
        
        // Apply vertical (X-axis rotation) first
        if verticalDegrees != 0 {
            let vRadians = verticalDegrees * .pi / 180.0
            transform = CATransform3DRotate(transform, vRadians, 1, 0, 0)
            
            if abs(verticalDegrees) > translateThresholdDegrees {
                let excess = abs(verticalDegrees) - translateThresholdDegrees
                let dir: CGFloat = verticalDegrees > 0 ? -1 : 1
                transform = CATransform3DTranslate(transform, 0, dir * excess * 2.0 * effectiveZoom, 0)
            }
        }
        
        // Then apply horizontal (Y-axis rotation)
        if horizontalDegrees != 0 {
            let hRadians = horizontalDegrees * .pi / 180.0
            transform = CATransform3DRotate(transform, hRadians, 0, 1, 0)
            
            if abs(horizontalDegrees) > translateThresholdDegrees {
                let excess = abs(horizontalDegrees) - translateThresholdDegrees
                let dir: CGFloat = horizontalDegrees > 0 ? -1 : 1
                transform = CATransform3DTranslate(transform, dir * excess * 2.0 * effectiveZoom, 0, 0)
            }
        }
        
        return transform
    }
    
    // MARK: - Perspective projection utilities for auto-zoom computation
    
    /// Projects a 2D displacement (relative to sublayerTransform center) through a CATransform3D.
    /// Assumes the input point lies on z = 0 (flat layer).
    ///
    /// Uses Core Animation's row-vector convention: `[x, y, 0, 1] * M`.
    static func projectDisplacement(_ d: CGPoint, through t: CATransform3D) -> CGPoint {
        let px = d.x * t.m11 + d.y * t.m21 + t.m41
        let py = d.x * t.m12 + d.y * t.m22 + t.m42
        let w  = d.x * t.m14 + d.y * t.m24 + t.m44
        guard abs(w) > 1e-10 else { return d }
        return CGPoint(x: px / w, y: py / w)
    }

    /// Returns `true` when every displacement in `corners` projects with a
    /// **positive** homogeneous `w` value through the given transform.
    ///
    /// When `w ≤ 0` a point is "behind the camera" and the perspective
    /// division flips the projected coordinates, making the resulting polygon
    /// degenerate.  Any containment test on such a polygon is meaningless,
    /// so callers should treat a `false` result as "invalid position".
    static func allProjectionsInFrontOfCamera(_ corners: [CGPoint], through t: CATransform3D) -> Bool {
        let minW: CGFloat = 1e-4
        for d in corners {
            let w = d.x * t.m14 + d.y * t.m24 + t.m44
            if w < minW { return false }
        }
        return true
    }
    
    /// Recenters the projected quad so it stays aligned to the view center.
    static func centeredTransform(
        _ transform: CATransform3D,
        imageCornerDisplacements: [CGPoint],
        targetCenter: CGPoint,
        factor: CGFloat
    ) -> CATransform3D {
        guard imageCornerDisplacements.count == 4 else {
            return transform
        }

        let clampedFactor = max(0, min(1, factor))
        guard clampedFactor > 0 else {
            return transform
        }

        let projectedCorners = imageCornerDisplacements.map { projectDisplacement($0, through: transform) }
        guard let minX = projectedCorners.map({ $0.x }).min(),
              let maxX = projectedCorners.map({ $0.x }).max(),
              let minY = projectedCorners.map({ $0.y }).min(),
              let maxY = projectedCorners.map({ $0.y }).max() else {
            return transform
        }

        let projectedCenter = CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        let delta = CGPoint(
            x: projectedCenter.x - targetCenter.x,
            y: projectedCenter.y - targetCenter.y
        )
        return CATransform3DTranslate(
            transform,
            -delta.x * clampedFactor,
            -delta.y * clampedFactor,
            0
        )
    }
    
    /// Tests whether all `testPoints` lie inside a polygon using ray casting.
    ///
    /// Works correctly for any simple polygon (convex or non-convex).
    /// For each test point, casts a horizontal ray to the right and counts
    /// edge crossings — an odd count means the point is inside.
    ///
    /// This replaces the previous cross-product convex polygon test, which
    /// failed when combined perspective rotations produced a slightly
    /// non-convex projected quad.
    static func allPointsInsideConvexPolygon(
        _ testPoints: [CGPoint],
        polygon: [CGPoint]
    ) -> Bool {
        let n = polygon.count
        guard n >= 3 else { return false }

        for point in testPoints {
            var inside = false
            var j = n - 1
            for i in 0..<n {
                let vi = polygon[i]
                let vj = polygon[j]
                // Check if the edge from vj to vi crosses the horizontal ray
                // cast to the right from the test point.
                if (vi.y > point.y) != (vj.y > point.y) {
                    let intersectX = vj.x + (point.y - vj.y) / (vi.y - vj.y) * (vi.x - vj.x)
                    if point.x < intersectX {
                        inside.toggle()
                    }
                }
                j = i
            }
            if !inside { return false }
        }
        return true
    }
    
    /// Computes the minimum scale factor for the sublayerTransform so that the
    /// projected image quadrilateral fully covers the visible rectangle.
    ///
    /// `CATransform3DScale(t, s, s, 1)` uniformly scales the projected positions by `s`
    /// (because `CATransform3DScale` post-multiplies the scale matrix, meaning
    /// `p * t * Scale` — the scale applies *after* projection).
    ///
    /// Therefore we only need one projection pass: we project the image corners at
    /// scale 1, then binary-search for the minimum `s` where
    /// `(visibleCorner / s)` lies inside the unscaled projected quad.
    ///
    /// - Parameters:
    ///   - imageCornerDisplacements: 4 image corner displacements from the sublayerTransform
    ///     center, in CW order (TL, TR, BR, BL).
    ///   - visibleHalfSize: Half the visible area dimensions.
    ///   - perspectiveTransform: The CATransform3D perspective rotation (without compensating scale).
    /// - Returns: Scale factor ≥ 1.0.
    static func computeCompensatingScale(
        imageCornerDisplacements: [CGPoint],
        visibleCornerDisplacements: [CGPoint],
        perspectiveTransform: CATransform3D
    ) -> CGFloat {
        // Project image corners once (at unit scale)
        let projectedCorners = imageCornerDisplacements.map {
            projectDisplacement($0, through: perspectiveTransform)
        }
        
        // Quick check: no scale needed?
        if allPointsInsideConvexPolygon(visibleCornerDisplacements, polygon: projectedCorners) {
            return 1.0
        }
        
        // Binary search: find minimum s where (visibleCorners / s) ⊂ projectedCorners
        var lo: CGFloat = 1.0
        var hi: CGFloat = 5.0
        
        for _ in 0..<30 {
            let mid = (lo + hi) / 2
            let shrunk = visibleCornerDisplacements.map { CGPoint(x: $0.x / mid, y: $0.y / mid) }
            if allPointsInsideConvexPolygon(shrunk, polygon: projectedCorners) {
                hi = mid
            } else {
                lo = mid
            }
        }
        
        return hi
    }
    
}
