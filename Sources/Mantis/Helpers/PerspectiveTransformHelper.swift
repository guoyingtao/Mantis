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
        
        let context = CIContext()
        return context.createCGImage(outputImage, from: outputImage.extent)
    }
}
