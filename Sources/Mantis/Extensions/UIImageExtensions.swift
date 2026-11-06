//
//  UIImageExtensions.swift
//  Mantis
//
//  Created by Yingtao Guo on 10/30/18.
//

import UIKit
import ImageIO
import MantisCore

extension UIImage.Orientation {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        case .left: return .left
        @unknown default: return .up
        }
    }
}

// The crop pipeline lives in MantisCore on CGImage; these wrappers feed it the
// UIImage's pixels and orientation. Sizes are in pixels, so an image with
// scale > 1 is cropped at its full resolution and returned with scale 1.
extension UIImage {
    func cgImageWithFixedOrientation() -> CGImage? {
        cgImage?.withFixedOrientation(imageOrientation.cgImagePropertyOrientation)
    }
    
    func isHorizontal() -> Bool {
        return size.width > size.height
    }
    
    func horizontalToVerticalRatio() -> CGFloat {
        return size.width / size.height
    }
    
    /// Crops with the CIImage pipeline when the image has more than
    /// `maxImagePixelCount` pixels, otherwise with the CGContext pipeline.
    func crop(by cropInfo: CropInfo, maxImagePixelCount: Int) -> UIImage? {
        guard let cgImage,
              let cropped = MantisCore.crop(cgImage,
                                            orientation: imageOrientation.cgImagePropertyOrientation,
                                            by: cropInfo,
                                            maxImagePixelCount: maxImagePixelCount) else {
            return nil
        }
        return UIImage(cgImage: cropped)
    }
    
    func crop(by cropInfo: CropInfo) -> UIImage? {
        guard let cropped = cgImage?.crop(by: cropInfo, orientation: imageOrientation.cgImagePropertyOrientation) else {
            return nil
        }
        return UIImage(cgImage: cropped)
    }
    
    /// Memory-efficient crop using the CIImage lazy pipeline.
    func cropWithCIImage(by cropInfo: CropInfo) -> UIImage? {
        guard let cropped = cgImage?.cropWithCIImage(by: cropInfo,
                                                     orientation: imageOrientation.cgImagePropertyOrientation) else {
            return nil
        }
        return UIImage(cgImage: cropped)
    }
    
    func getOutputCropImageSize(by cropInfo: CropInfo) -> CGSize {
        guard let cgImage else { return .zero }
        return cropInfo.outputImageSize(forImageSize: cgImage.orientedSize(imageOrientation.cgImagePropertyOrientation))
    }

    // MARK: - Large Image Support

    /// Maps UIImage.imageOrientation to the EXIF orientation integer.
    var exifOrientation: Int32 {
        Int32(imageOrientation.cgImagePropertyOrientation.rawValue)
    }

    /// Returns true when the image's total pixel count exceeds `maxPixelCount`.
    /// A `maxPixelCount` of 0 (or less) disables the check.
    func exceedsPixelCount(_ maxPixelCount: Int) -> Bool {
        guard maxPixelCount > 0 else { return false }
        return Int(size.width * scale) * Int(size.height * scale) > maxPixelCount
    }

    /// Returns a downsampled version of this image if its total pixel count exceeds `maxPixelCount`.
    /// When `sourceData` (the original encoded image data) is provided, uses an ImageIO
    /// thumbnail, which can decode subsampled and keeps peak memory low.
    /// Otherwise draws into a target-size context: one full decode, but no re-encode
    /// and no second decode. Note that `CGImage.dataProvider` returns decoded bitmap
    /// bytes (not the original encoded data), so it cannot feed ImageIO and is not used.
    /// Returns `self` unchanged if `maxPixelCount <= 0` or the image is within limits.
    ///
    /// This is the internal implementation; the public entry point is the
    /// `Mantis.downsample(image:maxPixelCount:sourceData:)` free function.
    func downsampledIfNeeded(maxPixelCount: Int, sourceData: Data? = nil) -> UIImage {
        guard exceedsPixelCount(maxPixelCount) else { return self }

        let pixelWidth = CGFloat(Int(size.width * scale))
        let pixelHeight = CGFloat(Int(size.height * scale))
        let ratio = CGFloat(maxPixelCount) / (pixelWidth * pixelHeight)
        let scaleFactor = sqrt(ratio)

        // 1. ImageIO thumbnail from the original encoded data (most memory-efficient path)
        if let sourceData = sourceData {
            let maxDimension = max(pixelWidth, pixelHeight) * scaleFactor
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: Int(ceil(maxDimension)),
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true
            ]
            if let source = CGImageSourceCreateWithData(sourceData as CFData, nil),
               let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                return UIImage(cgImage: thumbnail)
            }
        }

        // 2. Draw into a target-size context. draw(in:) bakes in the EXIF orientation,
        // matching the kCGImageSourceCreateThumbnailWithTransform behavior above.
        let targetSize = CGSize(width: max(1, floor(pixelWidth * scaleFactor)),
                                height: max(1, floor(pixelHeight * scaleFactor)))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
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
