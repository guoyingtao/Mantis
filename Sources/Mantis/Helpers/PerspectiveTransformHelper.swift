//
//  PerspectiveTransformHelper.swift
//  Mantis
//
//  Helper for computing CATransform3D perspective skew transforms
//  and CIPerspectiveTransform parameters for image export.
//

import UIKit
import CoreImage

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
    /// CIPerspectiveTransform maps the original image corners to new positions.
    /// To match the CATransform3D preview effect, we need to understand:
    /// - In preview: positive vertical skew tilts top toward viewer (top appears wider)
    /// - For CIPerspectiveTransform: we specify where each corner should go
    ///
    /// - Parameters:
    ///   - imageSize: The size of the source image
    ///   - horizontalDegrees: Horizontal skew angle (-30 to +30)
    ///   - verticalDegrees: Vertical skew angle (-30 to +30)
    /// - Returns: Tuple of 4 CIVector corner positions in CIImage coordinate system
    static func perspectiveCorners(
        for imageSize: CGSize,
        horizontalDegrees: CGFloat,
        verticalDegrees: CGFloat
    ) -> (topLeft: CIVector, topRight: CIVector, bottomLeft: CIVector, bottomRight: CIVector) {
        let w = imageSize.width
        let h = imageSize.height
        
        // CIImage coordinate system: origin at bottom-left, Y goes up
        // So "top" has high Y value, "bottom" has low Y value
        // Start with original corners
        var tl = CGPoint(x: 0, y: h)      // top-left (high Y)
        var tr = CGPoint(x: w, y: h)      // top-right (high Y)
        var bl = CGPoint(x: 0, y: 0)      // bottom-left (low Y)
        var br = CGPoint(x: w, y: 0)      // bottom-right (low Y)
        
        // Calculate the perspective effect intensity based on angle
        let hRadians = horizontalDegrees * .pi / 180.0
        let vRadians = verticalDegrees * .pi / 180.0
        
        // Horizontal skew: rotation around vertical axis
        // Positive = right side recedes, left side forward
        // Negative = left side recedes, right side forward
        if horizontalDegrees != 0 {
            let intensity = sin(abs(hRadians))
            let verticalShrink = h * intensity * 0.25
            let horizontalShift = w * intensity * 0.12
            
            if horizontalDegrees > 0 {
                // Right side recedes: right corners move inward and closer together
                tr.x -= horizontalShift
                br.x -= horizontalShift
                // In CI coords: top-right Y decreases, bottom-right Y increases (shrinking the right edge)
                tr.y -= verticalShrink / 2
                br.y += verticalShrink / 2
            } else {
                // Left side recedes
                tl.x += horizontalShift
                bl.x += horizontalShift
                tl.y -= verticalShrink / 2
                bl.y += verticalShrink / 2
            }
        }
        
        // Vertical skew: rotation around horizontal axis
        // In preview with positive degrees: top tilts toward viewer (appears wider)
        // So for output: positive = bottom edge shrinks (moves inward horizontally)
        if verticalDegrees != 0 {
            let intensity = sin(abs(vRadians))
            let horizontalShrink = w * intensity * 0.25
            let verticalShift = h * intensity * 0.12
            
            if verticalDegrees > 0 {
                // Positive: bottom recedes (narrower), top stays wide
                // Bottom corners move inward horizontally
                bl.x += horizontalShrink / 2
                br.x -= horizontalShrink / 2
                // Bottom edge also moves up slightly (in CI coords, Y increases)
                bl.y += verticalShift
                br.y += verticalShift
            } else {
                // Negative: top recedes (narrower), bottom stays wide
                // Top corners move inward horizontally
                tl.x += horizontalShrink / 2
                tr.x -= horizontalShrink / 2
                // Top edge moves down (in CI coords, Y decreases)
                tl.y -= verticalShift
                tr.y -= verticalShift
            }
        }
        
        return (
            topLeft: CIVector(x: tl.x, y: tl.y),
            topRight: CIVector(x: tr.x, y: tr.y),
            bottomLeft: CIVector(x: bl.x, y: bl.y),
            bottomRight: CIVector(x: br.x, y: br.y)
        )
    }
    
    /// Applies perspective transform to a CGImage to match the preview appearance.
    ///
    /// The preview uses CATransform3D with m34 = -1/500 applied via sublayerTransform.
    /// This method renders the image using the same CATransform3D approach to ensure
    /// the output matches the preview exactly.
    ///
    /// Returns nil if no skew is applied or if rendering fails.
    static func applyPerspectiveTransform(
        to cgImage: CGImage,
        horizontalDegrees: CGFloat,
        verticalDegrees: CGFloat
    ) -> CGImage? {
        guard horizontalDegrees != 0 || verticalDegrees != 0 else {
            return nil
        }
        
        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        
        // Get the exact CATransform3D used in preview
        let transform = combinedSkewTransform3D(
            horizontalDegrees: horizontalDegrees,
            verticalDegrees: verticalDegrees
        )
        
        // Use a virtual size to calculate perspective ratios
        let virtualSize: CGFloat = 350.0
        let halfVirtual = virtualSize / 2.0
        
        // Define corners centered at origin (UIKit coordinates: Y down)
        let cornersUIKit = [
            CGPoint(x: -halfVirtual, y: -halfVirtual),  // top-left
            CGPoint(x: halfVirtual, y: -halfVirtual),   // top-right
            CGPoint(x: halfVirtual, y: halfVirtual),    // bottom-right
            CGPoint(x: -halfVirtual, y: halfVirtual)    // bottom-left
        ]
        
        // Project through CATransform3D
        let projectedUIKit = cornersUIKit.map { projectDisplacement($0, through: transform) }
        
        // Calculate displacement ratios
        var displacementRatios: [CGPoint] = []
        for i in 0..<4 {
            let dx = (projectedUIKit[i].x - cornersUIKit[i].x) / halfVirtual
            let dy = (projectedUIKit[i].y - cornersUIKit[i].y) / halfVirtual
            displacementRatios.append(CGPoint(x: dx, y: dy))
        }
        
        let halfW = w / 2.0
        let halfH = h / 2.0
        let scaleFactor: CGFloat = 1.5
        
        // Calculate projected corners in UIKit coordinates (origin top-left, Y down)
        // Original corners: TL(0,0), TR(w,0), BR(w,h), BL(0,h)
        // Displacements are relative to center, so we apply them from each corner's position
        let projTL = CGPoint(
            x: 0 + displacementRatios[0].x * halfW * scaleFactor,
            y: 0 + displacementRatios[0].y * halfH * scaleFactor
        )
        let projTR = CGPoint(
            x: w + displacementRatios[1].x * halfW * scaleFactor,
            y: 0 + displacementRatios[1].y * halfH * scaleFactor
        )
        let projBR = CGPoint(
            x: w + displacementRatios[2].x * halfW * scaleFactor,
            y: h + displacementRatios[2].y * halfH * scaleFactor
        )
        let projBL = CGPoint(
            x: 0 + displacementRatios[3].x * halfW * scaleFactor,
            y: h + displacementRatios[3].y * halfH * scaleFactor
        )
        
        // Find the bounding box of projected corners
        let allX = [projTL.x, projTR.x, projBR.x, projBL.x]
        let allY = [projTL.y, projTR.y, projBR.y, projBL.y]
        let minProjX = allX.min()!
        let maxProjX = allX.max()!
        let minProjY = allY.min()!
        let maxProjY = allY.max()!
        
        // Calculate the inscribed rectangle (no black areas)
        let insideLeft = max(projTL.x, projBL.x)
        let insideRight = min(projTR.x, projBR.x)
        let insideTop = max(projTL.y, projTR.y)
        let insideBottom = min(projBL.y, projBR.y)
        
        // Output size is the inscribed rectangle
        let outputWidth = insideRight - insideLeft
        let outputHeight = insideBottom - insideTop
        
        guard outputWidth > 10 && outputHeight > 10 else {
            return nil
        }
        
        // Now use CIPerspectiveTransform with corners adjusted so the inscribed
        // rectangle maps to the full output
        
        // Convert to CIImage coordinates (origin bottom-left, Y up)
        // and shift so inscribed rect starts at origin
        let ciTL = CGPoint(
            x: projTL.x - insideLeft,
            y: outputHeight - (projTL.y - insideTop)
        )
        let ciTR = CGPoint(
            x: projTR.x - insideLeft,
            y: outputHeight - (projTR.y - insideTop)
        )
        let ciBR = CGPoint(
            x: projBR.x - insideLeft,
            y: outputHeight - (projBR.y - insideTop)
        )
        let ciBL = CGPoint(
            x: projBL.x - insideLeft,
            y: outputHeight - (projBL.y - insideTop)
        )
        
        let ciImage = CIImage(cgImage: cgImage)
        
        guard let filter = CIFilter(name: "CIPerspectiveTransform") else {
            return nil
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: ciTL.x, y: ciTL.y), forKey: "inputTopLeft")
        filter.setValue(CIVector(x: ciTR.x, y: ciTR.y), forKey: "inputTopRight")
        filter.setValue(CIVector(x: ciBL.x, y: ciBL.y), forKey: "inputBottomLeft")
        filter.setValue(CIVector(x: ciBR.x, y: ciBR.y), forKey: "inputBottomRight")
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        let context = CIContext()
        
        // Crop to exactly the inscribed rectangle area
        // The output extent should now be positioned such that (0,0) to (outputWidth, outputHeight)
        // contains the valid image content
        let cropRect = CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight)
        let finalRect = cropRect.intersection(outputImage.extent)
        
        if !finalRect.isNull && finalRect.width > 10 && finalRect.height > 10 {
            return context.createCGImage(outputImage, from: finalRect)
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
