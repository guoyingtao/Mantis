//
//  ToolBarButtonImageBuilder.swift
//  Mantis
//
//  Created by Echo on 11/6/18.
//
//  This class is directly tranlated into swift from TOActivityCroppedImageProvider.m
//  in this project https://github.com/TimOliver/TOCropViewController
//
//  Copyright 2015-2018 Timothy Oliver. All rights reserved.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

struct ToolBarButtonImageBuilder {
    static func rotateCCWImage() -> UIImage? {
        if #available(macCatalyst 13.1, iOS 13.0, *) {
            return UIImage(systemName: "rotate.left")
        }
        
        return drawRotateCCWImage()
    }
    
    static func rotateCWImage() -> UIImage? {
        if #available(macCatalyst 13.1, iOS 13.0, *) {
            return UIImage(systemName: "rotate.right")
        }
        
        return drawRotateCWImage()
    }
    
    static func flipHorizontally() -> UIImage? {
        if #available(macCatalyst 13.1, iOS 13.0, *) {
            return UIImage(systemName: "flip.horizontal")
        }
        
        return drawFlipHorizontally()
    }
    
    static func flipVertically() -> UIImage? {
        drawFlipVertically()
    }
    
    static func clampImage() -> UIImage? {
        if #available(macCatalyst 13.1, iOS 13.0, *) {
            return UIImage(systemName: "aspectratio")
        }
        
        return drawClampImage()
    }
    
    static func resetImage() -> UIImage? {
        if #available(macCatalyst 13.1, iOS 13.0, *) {
            return UIImage(systemName: "arrow.2.circlepath")
        }
        
        return drawResetImage()
    }
    
    static func alterCropper90DegreeImage() -> UIImage? {
        drawAlterCropper90DegreeImage()
    }
    
    static func horizontallyFlipImage() -> UIImage? {
        if #available(macCatalyst 13.1, iOS 13.0, *) {
            return UIImage(systemName: "flip.horizontal")
        }
        
        return nil
    }
    
    static func verticallyFlipImage() -> UIImage? {
        if #available(macCatalyst 13.1, iOS 13.0, *) {
            guard let horizontallyFlippedImage = horizontallyFlipImage(),
                  let cgImage = horizontallyFlippedImage.cgImage else {
                return nil
            }
            
            let rotatedImage = UIImage(cgImage: cgImage, scale: horizontallyFlippedImage.scale, orientation: .leftMirrored)
            
            let newSize = CGSize(width: horizontallyFlippedImage.size.height, height: horizontallyFlippedImage.size.width)
            UIGraphicsBeginImageContextWithOptions(newSize, false, horizontallyFlippedImage.scale)
            rotatedImage.draw(in: CGRect(origin: .zero, size: newSize))
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage
        }
        
        return nil
    }
    
    static func autoAdjustImage() -> UIImage? {
        if #available(macCatalyst 13.1, iOS 13.0, *) {
            return UIImage(systemName: "camera.metering.none")
        }
        
        return nil
    }
}
