//
//  PerspectiveTransformHelper.swift
//  Mantis
//
//  Helper for computing CATransform3D perspective skew transforms
//  and CIPerspectiveTransform parameters for image export.
//

import UIKit
import CoreImage

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
    static let maxSkewDegrees: CGFloat = 20.0
    
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
    
    /// Combines horizontal and vertical skew into a single CATransform3D
    static func combinedSkewTransform3D(horizontalDegrees: CGFloat, verticalDegrees: CGFloat) -> CATransform3D {
        if horizontalDegrees == 0 && verticalDegrees == 0 {
            return CATransform3DIdentity
        }
        
        var transform = CATransform3DIdentity
        transform.m34 = perspectiveDepth
        
        // Apply vertical (X-axis rotation) first
        if verticalDegrees != 0 {
            let vRadians = verticalDegrees * .pi / 180.0
            transform = CATransform3DRotate(transform, vRadians, 1, 0, 0)
            
            if abs(verticalDegrees) > translateThresholdDegrees {
                let excess = abs(verticalDegrees) - translateThresholdDegrees
                let dir: CGFloat = verticalDegrees > 0 ? -1 : 1
                transform = CATransform3DTranslate(transform, 0, dir * excess * 2.0, 0)
            }
        }
        
        // Then apply horizontal (Y-axis rotation)
        if horizontalDegrees != 0 {
            let hRadians = horizontalDegrees * .pi / 180.0
            transform = CATransform3DRotate(transform, hRadians, 0, 1, 0)
            
            if abs(horizontalDegrees) > translateThresholdDegrees {
                let excess = abs(horizontalDegrees) - translateThresholdDegrees
                let dir: CGFloat = horizontalDegrees > 0 ? -1 : 1
                transform = CATransform3DTranslate(transform, dir * excess * 2.0, 0, 0)
            }
        }
        
        return transform
    }
    
    // MARK: - CIPerspectiveTransform for image export
    
    /// Computes the four corner points for a CIPerspectiveTransform based on skew values.
    ///
    /// The corner adjustments simulate the same visual effect as the CATransform3D preview.
    /// - Parameters:
    ///   - imageSize: The size of the source image
    ///   - horizontalDegrees: Horizontal skew angle
    ///   - verticalDegrees: Vertical skew angle
    /// - Returns: Tuple of 4 CIVector corner positions (topLeft, topRight, bottomLeft, bottomRight)
    static func perspectiveCorners(
        for imageSize: CGSize,
        horizontalDegrees: CGFloat,
        verticalDegrees: CGFloat
    ) -> (topLeft: CIVector, topRight: CIVector, bottomLeft: CIVector, bottomRight: CIVector) {
        let w = imageSize.width
        let h = imageSize.height
        
        // Start with original corners (CIImage coordinate system: origin at bottom-left)
        var tl = CGPoint(x: 0, y: h)     // top-left in UIKit = top-left in CI (y is flipped in CI)
        var tr = CGPoint(x: w, y: h)     // top-right
        var bl = CGPoint(x: 0, y: 0)     // bottom-left
        var br = CGPoint(x: w, y: 0)     // bottom-right
        
        // Apply horizontal skew: rotate around vertical center axis
        // Positive = right side comes forward (appears larger)
        // Negative = left side comes forward (appears larger)
        if horizontalDegrees != 0 {
            let factor = abs(horizontalDegrees) / maxSkewDegrees
            let xShift = w * factor * 0.15  // How much the edges move inward
            let yShift = h * factor * 0.10  // How much height changes on the receding side
            
            if horizontalDegrees > 0 {
                // Right side recedes: right corners move inward
                tr.x -= xShift
                br.x -= xShift
                tr.y -= yShift
                br.y += yShift
            } else {
                // Left side recedes: left corners move inward
                tl.x += xShift
                bl.x += xShift
                tl.y -= yShift
                bl.y += yShift
            }
        }
        
        // Apply vertical skew: rotate around horizontal center axis
        if verticalDegrees != 0 {
            let factor = abs(verticalDegrees) / maxSkewDegrees
            let yShift = h * factor * 0.15
            let xShift = w * factor * 0.10
            
            if verticalDegrees > 0 {
                // Bottom recedes
                bl.y += yShift
                br.y += yShift
                bl.x += xShift
                br.x -= xShift
            } else {
                // Top recedes
                tl.y -= yShift
                tr.y -= yShift
                tl.x += xShift
                tr.x -= xShift
            }
        }
        
        return (
            topLeft: CIVector(x: tl.x, y: tl.y),
            topRight: CIVector(x: tr.x, y: tr.y),
            bottomLeft: CIVector(x: bl.x, y: bl.y),
            bottomRight: CIVector(x: br.x, y: br.y)
        )
    }
    
    /// Applies perspective correction to a CGImage.
    /// Returns nil if no skew is applied or if the filter fails.
    /// The output is automatically cropped to the largest inscribed rectangle
    /// to eliminate blank/transparent areas.
    static func applyPerspectiveTransform(
        to cgImage: CGImage,
        horizontalDegrees: CGFloat,
        verticalDegrees: CGFloat
    ) -> CGImage? {
        guard horizontalDegrees != 0 || verticalDegrees != 0 else {
            return nil
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let corners = perspectiveCorners(for: imageSize,
                                         horizontalDegrees: horizontalDegrees,
                                         verticalDegrees: verticalDegrees)
        
        guard let filter = CIFilter(name: "CIPerspectiveTransform") else {
            return nil
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(corners.topLeft, forKey: "inputTopLeft")
        filter.setValue(corners.topRight, forKey: "inputTopRight")
        filter.setValue(corners.bottomLeft, forKey: "inputBottomLeft")
        filter.setValue(corners.bottomRight, forKey: "inputBottomRight")
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        // Compute inscribed rectangle to crop out blank areas
        let tl = CGPoint(x: corners.topLeft.x, y: corners.topLeft.y)
        let tr = CGPoint(x: corners.topRight.x, y: corners.topRight.y)
        let bl = CGPoint(x: corners.bottomLeft.x, y: corners.bottomLeft.y)
        let br = CGPoint(x: corners.bottomRight.x, y: corners.bottomRight.y)
        let cropRect = inscribedRectInQuadrilateral(topLeft: tl, topRight: tr,
                                                     bottomLeft: bl, bottomRight: br)
        
        let context = CIContext()
        if cropRect.width > 0 && cropRect.height > 0 {
            return context.createCGImage(outputImage, from: cropRect)
        }
        return context.createCGImage(outputImage, from: outputImage.extent)
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
    
    /// Tests whether all `testPoints` lie inside a convex polygon.
    ///
    /// The polygon vertices must be in clockwise order (screen coordinates, Y downward).
    /// Uses the cross-product sign test: for CW winding, interior points
    /// produce a positive cross product for every edge.
    static func allPointsInsideConvexPolygon(
        _ testPoints: [CGPoint],
        polygon: [CGPoint]
    ) -> Bool {
        let n = polygon.count
        guard n >= 3 else { return false }
        
        for point in testPoints {
            for i in 0..<n {
                let a = polygon[i]
                let b = polygon[(i + 1) % n]
                let cross = (b.x - a.x) * (point.y - a.y) - (b.y - a.y) * (point.x - a.x)
                if cross < -1e-6 {
                    return false
                }
            }
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
        visibleHalfSize: CGSize,
        perspectiveTransform: CATransform3D
    ) -> CGFloat {
        // Project image corners once (at unit scale)
        let projectedCorners = imageCornerDisplacements.map {
            projectDisplacement($0, through: perspectiveTransform)
        }
        
        // Visible area corners (relative to center)
        let visibleCorners = [
            CGPoint(x: -visibleHalfSize.width, y: -visibleHalfSize.height),
            CGPoint(x:  visibleHalfSize.width, y: -visibleHalfSize.height),
            CGPoint(x:  visibleHalfSize.width, y:  visibleHalfSize.height),
            CGPoint(x: -visibleHalfSize.width, y:  visibleHalfSize.height)
        ]
        
        // Quick check: no scale needed?
        if allPointsInsideConvexPolygon(visibleCorners, polygon: projectedCorners) {
            return 1.0
        }
        
        // Binary search: find minimum s where (visibleCorners / s) ⊂ projectedCorners
        var lo: CGFloat = 1.0
        var hi: CGFloat = 5.0
        
        for _ in 0..<30 {
            let mid = (lo + hi) / 2
            let shrunk = visibleCorners.map { CGPoint(x: $0.x / mid, y: $0.y / mid) }
            if allPointsInsideConvexPolygon(shrunk, polygon: projectedCorners) {
                hi = mid
            } else {
                lo = mid
            }
        }
        
        // Tiny margin for sub-pixel safety
        return hi * 1.002
    }
    
    /// Computes a conservative axis-aligned inscribed rectangle within the
    /// quadrilateral defined by four perspective-transformed corners.
    ///
    /// The corners are in CI coordinate space (origin at bottom-left, Y upward).
    private static func inscribedRectInQuadrilateral(
        topLeft tl: CGPoint,
        topRight tr: CGPoint,
        bottomLeft bl: CGPoint,
        bottomRight br: CGPoint
    ) -> CGRect {
        // In CIImage coords: Y goes up, so "top" = high Y, "bottom" = low Y.
        let minX = max(tl.x, bl.x)
        let maxX = min(tr.x, br.x)
        let minY = max(bl.y, br.y)   // bottom inner edge (low Y)
        let maxY = min(tl.y, tr.y)   // top inner edge (high Y)
        
        guard maxX > minX && maxY > minY else { return .zero }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
