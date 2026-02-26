//
//  UIImageExtensions.swift
//  Mantis
//
//  Created by Yingtao Guo on 10/30/18.
//

import UIKit
import CoreImage
import ImageIO

extension UIImage {
    func cgImageWithFixedOrientation() -> CGImage? {
        if imageOrientation == .up {
            return cgImage
        }
        
        guard let cgImage = cgImage, let colorSpace = cgImage.colorSpace else {
            return nil
        }
        
        let width  = size.width
        let height = size.height
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: width, y: height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.rotated(by: 0.5 * .pi)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.rotated(by: -0.5 * .pi)
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        var context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: UInt32(cgImage.bitmapInfo.rawValue)
            )
        
        if context == nil {
            context = cgImage.createBackupCGContext(size: size, bitmapBytesPerRow: 0, colorSpaceRef: colorSpace)
        }
        
        guard let context else {
            return nil
        }
        
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        return context.makeImage()
    }
    
    func isHorizontal() -> Bool {
        return size.width > size.height
    }
    
    func horizontalToVerticalRatio() -> CGFloat {
        return size.width / size.height
    }
    
    func crop(by cropInfo: CropInfo) -> UIImage? {
        guard let fixedOrientationImage = cgImageWithFixedOrientation() else {
            return nil
        }
        
        let hasSkew = cropInfo.horizontalSkewDegrees != 0 || cropInfo.verticalSkewDegrees != 0
        
        if hasSkew {
            // When skew is applied, use CIPerspectiveCorrection to extract the correct
            // quadrilateral from the source image, matching the preview's perspective warp.
            return cropWithPerspective(fixedOrientationImage, cropInfo: cropInfo)
        }
        
        var transform = CGAffineTransform.identity
        transform.transformed(by: cropInfo)
        
        let outputSize = getOutputCropImageSize(by: cropInfo)
        
        do {
            guard let transformedCGImage = try fixedOrientationImage.transformedImage(transform,
                                                                                      outputSize: outputSize,
                                                                                      cropSize: cropInfo.cropSize,
                                                                                      imageViewSize: cropInfo.imageViewSize) else {
                return nil
            }
            
            return UIImage(cgImage: transformedCGImage)
        } catch {
            print("*** Failed to get transfromed image ***")

            if let error = error as? ImageProcessError {
                print("Failed reason: \(error)")
            }
            
            return nil
        }
    }
    
    /// Crops the image with perspective skew applied, matching the preview rendering.
    ///
    /// The preview rendering pipeline:
    /// 1. Image is in imageContainer (inside scroll view content)
    /// 2. sublayerTransform (3D perspective) is applied around scroll view center
    /// 3. Scroll view has 2D transform (rotation + flip) around its center
    /// 4. Crop box selects a rectangle from the screen-space result
    ///
    /// To find which source image pixels correspond to the crop box:
    /// 1. Express crop box corners in screen space relative to scroll view center
    /// 2. Apply inverse 2D transform → content-space coordinates relative to anchor
    /// 3. Apply inverse perspective projection → un-warped content coordinates
    /// 4. Convert to image pixel coordinates
    /// 5. Use CIPerspectiveCorrection to extract that quad
    private func cropWithPerspective(_ cgImage: CGImage, cropInfo: CropInfo) -> UIImage? {
        let imageViewSize = cropInfo.imageViewSize
        let cropSize = cropInfo.cropSize
        let zoomScaleX = abs(cropInfo.scaleX)
        let zoomScaleY = abs(cropInfo.scaleY)

        let outputWidth = round((size.width / imageViewSize.width * cropSize.width) / zoomScaleX)
        let outputHeight = round((size.height / imageViewSize.height * cropSize.height) / zoomScaleY)
        guard outputWidth > 0 && outputHeight > 0 else { return nil }

        let scrollBoundsSize = cropInfo.scrollBoundsSize
        let scrollContentOffset = cropInfo.scrollContentOffset
        let imgContainerFrame = cropInfo.imageContainerFrame
        let sublayerTransform = cropInfo.skewSublayerTransform

        // sublayerTransform anchor in content coordinates
        let anchorX = scrollContentOffset.x + scrollBoundsSize.width / 2
        let anchorY = scrollContentOffset.y + scrollBoundsSize.height / 2

        // Step 1: Crop box corners in screen space, relative to scroll view center.
        let halfCropW = cropSize.width / 2
        let halfCropH = cropSize.height / 2
        let screenCorners = [
            CGPoint(x: -halfCropW, y: -halfCropH), // TL
            CGPoint(x: halfCropW, y: -halfCropH), // TR
            CGPoint(x: halfCropW, y: halfCropH), // BR
            CGPoint(x: -halfCropW, y: halfCropH)  // BL
        ]

        // Step 2: Apply inverse 2D transform to go from screen space to content space.
        //
        // The scroll view's actual CGAffineTransform (rotation + flip) is used
        // directly instead of reconstructing from decomposed rotation / scale
        // values. The flip() method builds the transform via
        //   R(rot) · S(flip) · R(extra)
        // which does not decompose cleanly into a single rotation + scale pair.
        let inverseTransform = cropInfo.scrollViewTransform.inverted()

        let contentCorners = screenCorners.map { point -> CGPoint in
            point.applying(inverseTransform)
        }

        // Step 3: Inverse-project through sublayerTransform to find un-warped content positions
        let sourceContentDisplacements = contentCorners.map { corner in
            inverseProjectDisplacement(corner, through: sublayerTransform)
        }

        // Step 4: Convert from content-space displacements (from anchor) to image pixel coordinates
        let pixelScaleX = CGFloat(cgImage.width) / imageViewSize.width
        let pixelScaleY = CGFloat(cgImage.height) / imageViewSize.height

        let sourcePixelPoints = sourceContentDisplacements.map { disp -> CGPoint in
            // Content coordinates (absolute)
            let contentX = disp.x + anchorX
            let contentY = disp.y + anchorY

            // Image container local coordinates
            let localX = contentX - imgContainerFrame.origin.x
            let localY = contentY - imgContainerFrame.origin.y

            // Scale from container frame size to imageView bounds size
            let boundsX = localX / imgContainerFrame.width * imageViewSize.width
            let boundsY = localY / imgContainerFrame.height * imageViewSize.height

            // To pixel coordinates
            return CGPoint(x: boundsX * pixelScaleX, y: boundsY * pixelScaleY)
        }

        // Step 5: Use CIPerspectiveCorrection to extract the quadrilateral.
        // CIPerspectiveCorrection uses Core Image coordinates (origin at bottom-left),
        // so flip Y from pixel coordinates (origin at top-left).
        let imgHeight = CGFloat(cgImage.height)
        let pts = sourcePixelPoints.map { CGPoint(x: $0.x, y: imgHeight - $0.y) }

        let ciImage = CIImage(cgImage: cgImage)

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: pts[0].x, y: pts[0].y), forKey: "inputTopLeft")
        filter.setValue(CIVector(x: pts[1].x, y: pts[1].y), forKey: "inputTopRight")
        filter.setValue(CIVector(x: pts[2].x, y: pts[2].y), forKey: "inputBottomRight")
        filter.setValue(CIVector(x: pts[3].x, y: pts[3].y), forKey: "inputBottomLeft")

        guard let correctedOutput = filter.outputImage else { return nil }

        // Render at desired output size
        let renderScaleX = outputWidth / correctedOutput.extent.width
        let renderScaleY = outputHeight / correctedOutput.extent.height
        let scaledImage = correctedOutput.transformed(by: CGAffineTransform(scaleX: renderScaleX, y: renderScaleY))

        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let resultCG = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: resultCG)
    }

    /// Inverse-projects a 2D point through a CATransform3D.
    ///
    /// Given the forward projection `projected = project(source, T)`, this finds `source`
    /// given `projected` and `T`.
    ///
    /// For a point on the z=0 plane, the forward projection is:
    ///   px = (x * m11 + y * m21 + m41) / w
    ///   py = (x * m12 + y * m22 + m42) / w
    ///   w  = (x * m14 + y * m24 + m44)
    ///
    /// Given (px, py), we solve for (x, y):
    ///   x * m11 + y * m21 + m41 = px * (x * m14 + y * m24 + m44)
    ///   x * m12 + y * m22 + m42 = py * (x * m14 + y * m24 + m44)
    ///
    /// Rearranging:
    ///   x * (m11 - px*m14) + y * (m21 - px*m24) = px*m44 - m41
    ///   x * (m12 - py*m14) + y * (m22 - py*m24) = py*m44 - m42
    private func inverseProjectDisplacement(_ projected: CGPoint, through transform: CATransform3D) -> CGPoint {
        let projX = projected.x
        let projY = projected.y

        let a11 = transform.m11 - projX * transform.m14
        let a12 = transform.m21 - projX * transform.m24
        let rhs1 = projX * transform.m44 - transform.m41

        let a21 = transform.m12 - projY * transform.m14
        let a22 = transform.m22 - projY * transform.m24
        let rhs2 = projY * transform.m44 - transform.m42

        let det = a11 * a22 - a12 * a21
        guard abs(det) > 1e-10 else { return projected }

        let srcX = (rhs1 * a22 - rhs2 * a12) / det
        let srcY = (a11 * rhs2 - a21 * rhs1) / det

        return CGPoint(x: srcX, y: srcY)
    }
    
    func getOutputCropImageSize(by cropInfo: CropInfo) -> CGSize {
        let zoomScaleX = abs(cropInfo.scaleX)
        let zoomScaleY = abs(cropInfo.scaleY)
        let cropSize = cropInfo.cropSize
        let imageViewSize = cropInfo.imageViewSize

        let expectedWidth = round((size.width / imageViewSize.width * cropSize.width) / zoomScaleX)
        let expectedHeight = round((size.height / imageViewSize.height * cropSize.height) / zoomScaleY)

        return CGSize(width: expectedWidth, height: expectedHeight)
    }

    // MARK: - Large Image Support

    /// Maps UIImage.imageOrientation to the EXIF orientation integer
    /// used by CIImage.oriented(forExifOrientation:).
    var exifOrientation: Int32 {
        switch imageOrientation {
        case .up:            return 1
        case .upMirrored:    return 2
        case .down:          return 3
        case .downMirrored:  return 4
        case .leftMirrored:  return 5
        case .right:         return 6
        case .rightMirrored: return 7
        case .left:          return 8
        @unknown default:    return 1
        }
    }

    /// Returns a downsampled version of this image if its total pixel count exceeds `maxPixelCount`.
    /// Uses ImageIO for memory-efficient thumbnail generation without fully decoding the source.
    /// Returns `self` unchanged if `maxPixelCount <= 0` or the image is within limits.
    public func downsampledIfNeeded(maxPixelCount: Int) -> UIImage {
        guard maxPixelCount > 0 else { return self }

        let pixelWidth = Int(size.width * scale)
        let pixelHeight = Int(size.height * scale)
        let totalPixels = pixelWidth * pixelHeight

        guard totalPixels > maxPixelCount else { return self }

        let ratio = CGFloat(maxPixelCount) / CGFloat(totalPixels)
        let scaleFactor = sqrt(ratio)
        let maxDimension = max(CGFloat(pixelWidth), CGFloat(pixelHeight)) * scaleFactor

        guard let imageData = jpegData(compressionQuality: 1.0) ?? pngData(),
              let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return self
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(ceil(maxDimension)),
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]

        guard let thumbnailCGImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return self
        }

        return UIImage(cgImage: thumbnailCGImage)
    }

    /// Memory-efficient crop using CIImage lazy pipeline.
    /// Uses CIImage.oriented() for lazy EXIF fix and CIPerspectiveCorrection for extraction.
    /// Handles both standard (translate/rotate/scale/flip) and perspective (skew) crops uniformly.
    /// CIImage only decodes the source pixels needed for the output region via GPU tiling.
    func cropWithCIImage(by cropInfo: CropInfo) -> UIImage? {
        guard let cgImg = cgImage else { return nil }

        // Lazy orientation fix — no full-size CGContext allocation
        let ciImage = CIImage(cgImage: cgImg).oriented(forExifOrientation: exifOrientation)

        let orientedWidth = ciImage.extent.width
        let orientedHeight = ciImage.extent.height

        let imageViewSize = cropInfo.imageViewSize
        let cropSize = cropInfo.cropSize
        let zoomScaleX = abs(cropInfo.scaleX)
        let zoomScaleY = abs(cropInfo.scaleY)

        let outputWidth = round((orientedWidth / imageViewSize.width * cropSize.width) / zoomScaleX)
        let outputHeight = round((orientedHeight / imageViewSize.height * cropSize.height) / zoomScaleY)
        guard outputWidth > 0 && outputHeight > 0 else { return nil }

        // Compute source pixel quad from crop box corners + transforms
        // (same coordinate math as cropWithPerspective)
        let scrollBoundsSize = cropInfo.scrollBoundsSize
        let scrollContentOffset = cropInfo.scrollContentOffset
        let imgContainerFrame = cropInfo.imageContainerFrame
        let sublayerTransform = cropInfo.skewSublayerTransform

        let anchorX = scrollContentOffset.x + scrollBoundsSize.width / 2
        let anchorY = scrollContentOffset.y + scrollBoundsSize.height / 2

        let halfCropW = cropSize.width / 2
        let halfCropH = cropSize.height / 2
        let screenCorners = [
            CGPoint(x: -halfCropW, y: -halfCropH),
            CGPoint(x:  halfCropW, y: -halfCropH),
            CGPoint(x:  halfCropW, y:  halfCropH),
            CGPoint(x: -halfCropW, y:  halfCropH)
        ]

        let inverseTransform = cropInfo.scrollViewTransform.inverted()
        let contentCorners = screenCorners.map { $0.applying(inverseTransform) }
        let sourceContentDisplacements = contentCorners.map {
            inverseProjectDisplacement($0, through: sublayerTransform)
        }

        let pixelScaleX = orientedWidth / imageViewSize.width
        let pixelScaleY = orientedHeight / imageViewSize.height

        let sourcePixelPoints = sourceContentDisplacements.map { disp -> CGPoint in
            let contentX = disp.x + anchorX
            let contentY = disp.y + anchorY
            let localX = contentX - imgContainerFrame.origin.x
            let localY = contentY - imgContainerFrame.origin.y
            let boundsX = localX / imgContainerFrame.width * imageViewSize.width
            let boundsY = localY / imgContainerFrame.height * imageViewSize.height
            return CGPoint(x: boundsX * pixelScaleX, y: boundsY * pixelScaleY)
        }

        // CIImage coordinates: origin at bottom-left, flip Y
        let imgHeight = orientedHeight
        let pts = sourcePixelPoints.map { CGPoint(x: $0.x, y: imgHeight - $0.y) }

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: pts[0].x, y: pts[0].y), forKey: "inputTopLeft")
        filter.setValue(CIVector(x: pts[1].x, y: pts[1].y), forKey: "inputTopRight")
        filter.setValue(CIVector(x: pts[2].x, y: pts[2].y), forKey: "inputBottomRight")
        filter.setValue(CIVector(x: pts[3].x, y: pts[3].y), forKey: "inputBottomLeft")

        guard let correctedOutput = filter.outputImage else { return nil }

        let renderScaleX = outputWidth / correctedOutput.extent.width
        let renderScaleY = outputHeight / correctedOutput.extent.height
        let scaledImage = correctedOutput.transformed(by: CGAffineTransform(scaleX: renderScaleX, y: renderScaleY))

        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let resultCG = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: resultCG)
    }
}

extension UIImage {
    func getImageWithTransparentBackground(borderWidth: CGFloat = 0, borderColor: UIColor = .clear, pathBuilder: (CGRect) -> UIBezierPath) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        
        // Because imageRendererFormat is a read only property
        // Setting imageRendererFormat.opaque = false does not work
        // https://stackoverflow.com/a/59805317/288724
        let format = imageRendererFormat
        format.opaque = false
        
        let rect = CGRect(origin: .zero, size: size)
        
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let path: UIBezierPath
            
            if borderWidth > 0 {
                let edgeInsets = UIEdgeInsets(top: borderWidth, left: borderWidth, bottom: borderWidth, right: borderWidth)
                let innerRect = rect.inset(by: edgeInsets)
                path = pathBuilder(innerRect)
                borderColor.setStroke()
                path.lineWidth = borderWidth
                path.stroke()
            } else {
                path = pathBuilder(rect)
            }
            
            path.addClip()
            
            UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
                .draw(in: rect)
        }
    }
    
    func rectangleMasked(borderWidth: CGFloat = 0, borderColor: UIColor = .clear) -> UIImage? {
        return getImageWithTransparentBackground(borderWidth: borderWidth, borderColor: borderColor) {
            UIBezierPath(rect: $0)
        }
    }
    
    func ellipseMasked(borderWidth: CGFloat = 0, borderColor: UIColor = .clear) -> UIImage? {
        return getImageWithTransparentBackground(borderWidth: borderWidth, borderColor: borderColor) {
            UIBezierPath(ovalIn: $0)
        }
    }
    
    func roundRect(_ radius: CGFloat, borderWidth: CGFloat = 0, borderColor: UIColor = .clear) -> UIImage? {
        return getImageWithTransparentBackground(borderWidth: borderWidth, borderColor: borderColor) {
            UIBezierPath(roundedRect: $0, cornerRadius: radius)
        }
    }
    
    func heart(borderWidth: CGFloat = 0, borderColor: UIColor = .clear) -> UIImage? {
        return getImageWithTransparentBackground(borderWidth: borderWidth, borderColor: borderColor) {
            UIBezierPath(heartIn: $0)
        }
    }
    
    func clipPath(_ points: [CGPoint], borderWidth: CGFloat = 0, borderColor: UIColor = .clear) -> UIImage? {
        guard points.count >= 3 else {
            return nil
        }
        
        return getImageWithTransparentBackground(borderWidth: borderWidth, borderColor: borderColor) {rect in
            let newPoints = points.map { CGPoint(x: rect.origin.x + rect.width * $0.x, y: rect.origin.y + rect.height * $0.y) }
            
            let path = UIBezierPath()
            path.move(to: newPoints[0])
            
            for index in 1..<newPoints.count {
                path.addLine(to: newPoints[index])
            }
            
            path.close()
            
            return path
        }
    }
}
