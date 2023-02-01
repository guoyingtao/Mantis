//
//  CGImageExtensions.swift
//  Mantis
//
//  Created by Echo on 10/30/18.
//
//  This class is originally from CGImage+IGRPhotoTweakExtension.swift in
//  https://github.com/IGRSoft/IGRPhotoTweaks
//
// Copyright Vitalii Parovishnyk. All rights reserved.

import UIKit

extension CGImage {
    func transformedImage(_ transform: CGAffineTransform,
                          outputSize: CGSize,
                          cropSize: CGSize,
                          imageViewSize: CGSize) -> CGImage? {
        guard var colorSpaceRef = self.colorSpace else {
            return self
        }
        
        // If the color space does not allow output, default to the RGB color space
        if !colorSpaceRef.supportsOutput {
            colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        }
        
        let bitmapBytesPerRow = 0
        
        func getBitmapInfo() -> UInt32 {
            if colorSpaceRef.model == .rgb {
                switch(bitsPerPixel, bitsPerComponent) {
                case (16, 5):
                    return CGImageAlphaInfo.noneSkipFirst.rawValue
                case (24, 8), (32, 8), (48, 16), (64, 16):
                    return CGImageAlphaInfo.premultipliedLast.rawValue
                case (32, 10):
                    if #available(iOS 12, macOS 10.14, *) {
                        return CGImageAlphaInfo.alphaOnly.rawValue | CGImagePixelFormatInfo.RGBCIF10.rawValue
                    } else {
                        return bitmapInfo.rawValue
                    }
                case (128, 32):
                    return CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatComponents.rawValue
                default:
                    break
                }
            }
            
            return bitmapInfo.rawValue
        }
        
        guard let context = CGContext(data: nil,
                                      width: Int(round(outputSize.width)),
                                      height: Int(round(outputSize.height)),
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bitmapBytesPerRow,
                                      space: colorSpaceRef,
                                      bitmapInfo: getBitmapInfo()) else {
            return self
        }
                
        context.setFillColor(UIColor.clear.cgColor)
        context.fill(CGRect(x: 0,
                            y: 0,
                            width: outputSize.width,
                            height: outputSize.height))
        
        var uiCoords = CGAffineTransform(scaleX: outputSize.width / cropSize.width,
                                         y: outputSize.height / cropSize.height)
        uiCoords = uiCoords.translatedBy(x: cropSize.width / 2, y: cropSize.height / 2)
        uiCoords = uiCoords.scaledBy(x: 1.0, y: -1.0)
        
        context.concatenate(uiCoords)
        context.concatenate(transform)
        context.scaleBy(x: 1, y: -1)
        
        context.draw(self, in: CGRect(x: (-imageViewSize.width / 2),
                                      y: (-imageViewSize.height / 2),
                                      width: imageViewSize.width,
                                      height: imageViewSize.height))
        
        return context.makeImage()
    }
}
