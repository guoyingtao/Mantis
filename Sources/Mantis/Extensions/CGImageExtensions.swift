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

enum ImageProcessError: Error {
    case noColorSpace
    case failedToBuildContext(colorSpaceModel: CGColorSpaceModel,
                              bitsPerPixel: Int,
                              bitsPerComponent: Int)
}

extension CGImage {
    func transformedImage(_ transform: CGAffineTransform,
                          outputSize: CGSize,
                          cropSize: CGSize,
                          imageViewSize: CGSize) throws -> CGImage? {
        guard var colorSpaceRef = self.colorSpace else {
            throw ImageProcessError.noColorSpace
        }
        
        // If the color space does not allow output, default to the RGB color space
        if !colorSpaceRef.supportsOutput {
            colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        }
        
        var bitmapBytesPerRow = 0
        
        var bitmapInfoData = bitmapInfo.rawValue
        /*
         for Indexed Color Image (or Palette-based Image)
         we output the edited image with RGB format
         */
        if bitsPerPixel == 8 && bitsPerComponent == 8 {
            bitmapBytesPerRow = Int(round(outputSize.width)) * 4
            bitmapInfoData = CGImageAlphaInfo.noneSkipLast.rawValue
        }
        
        let context = CGContext(data: nil,
                                width: Int(round(outputSize.width)),
                                height: Int(round(outputSize.height)),
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bitmapBytesPerRow,
                                space: colorSpaceRef,
                                bitmapInfo: bitmapInfoData)
        ??
        CGContext(data: nil,
                  width: Int(round(outputSize.width)),
                  height: Int(round(outputSize.height)),
                  bitsPerComponent: bitsPerComponent,
                  bytesPerRow: bitmapBytesPerRow,
                  space: colorSpaceRef,
                  bitmapInfo: getBackupBitmapInfo(colorSpaceRef))
        
        guard let context = context else {
            throw ImageProcessError.failedToBuildContext(colorSpaceModel: colorSpaceRef.model,
                                                         bitsPerPixel: bitsPerPixel,
                                                         bitsPerComponent: bitsPerComponent)
        }
        
        context.setFillColor(UIColor.clear.cgColor)
        context.fill(CGRect(origin: .zero, size: outputSize))
        
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
    
    /**
     Just in case the bitmapInfo from original image is not supported by CGContext, we will use this backup bitmapInfo instead.
     */
    private func getBackupBitmapInfo(_ colorSpaceRef: CGColorSpace) -> UInt32 {
        // https://developer.apple.com/forums/thread/679891
        if colorSpaceRef.model == .rgb {
            switch(bitsPerPixel, bitsPerComponent) {
            case (16, 5):
                return CGImageAlphaInfo.noneSkipFirst.rawValue
            case (24, 8), (48, 16):
                return CGImageAlphaInfo.noneSkipLast.rawValue
            case (32, 8), (64, 16):
                return CGImageAlphaInfo.premultipliedLast.rawValue
            case (32, 10):
                if #available(iOS 12, macOS 10.14, *) {
                    return CGImageAlphaInfo.alphaOnly.rawValue | CGImagePixelFormatInfo.RGBCIF10.rawValue
                } else {
                    break
                }
            case (128, 32):
                return CGImageAlphaInfo.premultipliedLast.rawValue | (bitmapInfo.rawValue & CGBitmapInfo.floatComponents.rawValue)
            default:
                break
            }
        }
        
        return bitmapInfo.rawValue
    }
}
