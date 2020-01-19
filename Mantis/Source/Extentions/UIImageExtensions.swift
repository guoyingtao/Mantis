//
//  UIImageExtensions.swift
//  Mantis
//
//  Created by Echo on 10/30/18.
//
//  This class is from UIImage+IGRPhotoTweakExtension.swift in
//  https://github.com/IGRSoft/IGRPhotoTweaks
//
// Copyright Vitalii Parovishnyk. All rights reserved.

import UIKit

extension UIImage {
    
    func cgImageWithFixedOrientation() -> CGImage? {
        
        guard let cgImage = self.cgImage, let colorSpace = cgImage.colorSpace else {
            return nil
        }
        
        if self.imageOrientation == UIImage.Orientation.up {
            return self.cgImage
        }
        
        let width  = self.size.width
        let height = self.size.height
        
        var transform = CGAffineTransform.identity
        
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: width, y: height)
            transform = transform.rotated(by: CGFloat.pi)
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.rotated(by: 0.5 * CGFloat.pi)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.rotated(by: -0.5 * CGFloat.pi)
            
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        
        switch self.imageOrientation {
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
        
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
            
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        // And now we just create a new UIImage from the drawing context
        guard let newCGImg = context.makeImage() else {
            return nil
        }
        
        return newCGImg
    }
    
    func isHorizontal() -> Bool {
        let orientationArray: [UIImage.Orientation] = [.up,.upMirrored,.down,.downMirrored]
        
        if orientationArray.contains(imageOrientation) {
            return size.width > size.height
        } else {
            return size.height > size.width
        }
    }
    
    func ratioH() -> CGFloat {
        let orientationArray: [UIImage.Orientation] = [.up,.upMirrored,.down,.downMirrored]
        if orientationArray.contains(imageOrientation) {
            return size.width / size.height
        } else {
            return size.height / size.width
        }
    }
    
    func getCroppedImage(byCropInfo info: CropInfo) -> UIImage? {
        guard let fixedImage = self.cgImageWithFixedOrientation() else {
            return nil
        }
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: info.translation.x, y: info.translation.y)
        transform = transform.rotated(by: info.rotation)
        transform = transform.scaledBy(x: info.scale, y: info.scale)
        
        guard let imageRef = fixedImage.transformedImage(transform,
                                                         zoomScale: info.scale,
                                                         sourceSize: self.size,
                                                         cropSize: info.cropSize,
                                                         imageViewSize: info.imageViewSize) else {
                                                            return nil
        }
        
        return UIImage(cgImage: imageRef)
    }
    
}

extension UIImage {
    func getImageWithTransparentBackground(pathBuilder: (CGRect) -> UIBezierPath) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        
        // Because imageRendererFormat is a read only property
        // Setting imageRendererFormat.opaque = false does not work
        // https://stackoverflow.com/a/59805317/288724
        let format = imageRendererFormat
        format.opaque = false
        
        let rect = CGRect(origin: .zero, size: size)
        
        return UIGraphicsImageRenderer(size: size, format: format).image() {
            _ in
            pathBuilder(rect).addClip()
            UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
                .draw(in: rect)
        }
    }
    
    var ellipseMasked: UIImage? {
        return getImageWithTransparentBackground() {
            UIBezierPath(ovalIn: $0)
        }
    }
    
    func roundRect(_ radius: CGFloat) -> UIImage? {
        return getImageWithTransparentBackground() {
            UIBezierPath(roundedRect: $0, cornerRadius: radius)
        }
    }
}
