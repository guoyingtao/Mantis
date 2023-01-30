//
//  UIImageExtensions.swift
//  Mantis
//
//  Created by Yingtao Guo on 10/30/18.
//

import UIKit

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
        
        guard let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: UInt32(cgImage.bitmapInfo.rawValue)
            ) else {
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
        let orientationArray: [UIImage.Orientation] = [.up, .upMirrored, .down, .downMirrored]
        if orientationArray.contains(imageOrientation) {
            return size.width > size.height
        } else {
            return size.height > size.width
        }
    }
    
    func horizontalToVerticalRatio() -> CGFloat {
        let orientationArray: [UIImage.Orientation] = [.up, .upMirrored, .down, .downMirrored]
        if orientationArray.contains(imageOrientation) {
            return size.width / size.height
        } else {
            return size.height / size.width
        }
    }
    
    func crop(by cropInfo: CropInfo) -> UIImage? {
        guard let fixedOrientationImage = cgImageWithFixedOrientation() else {
            return nil
        }
        
        var transform = CGAffineTransform.identity
        transform.transformed(by: cropInfo)
        
        let outputSize = getOutputCropImageSize(by: cropInfo)
        guard let transformedCGImage = fixedOrientationImage.transformedImage(transform,
                                                                              outputSize: outputSize,
                                                                              cropSize: cropInfo.cropSize,
                                                                              imageViewSize: cropInfo.imageViewSize) else {
            return nil
        }
        
        return UIImage(cgImage: transformedCGImage)
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
