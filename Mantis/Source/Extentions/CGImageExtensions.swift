//
//  CGImageExtensions.swift
//  Mantis
//
//  Created by Echo on 10/30/18.
//
//  This class is from CGImage+IGRPhotoTweakExtension.swift in
//  https://github.com/IGRSoft/IGRPhotoTweaks
//
// Copyright Vitalii Parovishnyk. All rights reserved.

import UIKit

extension CGImage {
    
    func transformedImage(_ transform: CGAffineTransform, zoomScale: CGFloat, sourceSize: CGSize, cropSize: CGSize, imageViewSize: CGSize) -> CGImage? {
        guard var colorSpaceRef = self.colorSpace else {
            return self
        }
        // If the color space does not allow output, default to the RGB color space
        if (!colorSpaceRef.supportsOutput) {
            colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        }
        
        let expectedWidth = floor(sourceSize.width / imageViewSize.width * cropSize.width) / zoomScale
        let expectedHeight = floor(sourceSize.height / imageViewSize.height * cropSize.height) / zoomScale
        let outputSize = CGSize(width: expectedWidth, height: expectedHeight)
        let bitmapBytesPerRow = 0
        
        var context = CGContext(data: nil,
                                width: Int(outputSize.width),
                                height: Int(outputSize.height),
                                bitsPerComponent: self.bitsPerComponent,
                                bytesPerRow: bitmapBytesPerRow,
                                space: colorSpaceRef,
                                bitmapInfo: self.bitmapInfo.rawValue)

        if context == nil {
            context = CGContext(data: nil,
            width: Int(outputSize.width),
            height: Int(outputSize.height),
            bitsPerComponent: self.bitsPerComponent,
            bytesPerRow: bitmapBytesPerRow,
            space: colorSpaceRef,
            bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)
        }
        
        if context == nil {
            context = CGContext(data: nil,
            width: Int(outputSize.width),
            height: Int(outputSize.height),
            bitsPerComponent: self.bitsPerComponent,
            bytesPerRow: bitmapBytesPerRow,
            space: colorSpaceRef,
            bitmapInfo:CGImageAlphaInfo.premultipliedFirst.rawValue)
        }
        
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(CGRect(x: 0,
                             y: 0,
                             width: outputSize.width,
                             height: outputSize.height))
        
        var uiCoords = CGAffineTransform(scaleX: outputSize.width / cropSize.width,
                                         y: outputSize.height / cropSize.height)
        uiCoords = uiCoords.translatedBy(x: cropSize.width / 2, y: cropSize.height / 2)
        uiCoords = uiCoords.scaledBy(x: 1.0, y: -1.0)
        
        context?.concatenate(uiCoords)
        context?.concatenate(transform)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.draw(self, in: CGRect(x: (-imageViewSize.width / 2),
                                       y: (-imageViewSize.height / 2),
                                       width: imageViewSize.width,
                                       height: imageViewSize.height))
        
        let result = context?.makeImage()
        
        return result
    }
}
