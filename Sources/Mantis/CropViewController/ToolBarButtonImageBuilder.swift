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
        UIImage(systemName: "rotate.left")
    }

    static func rotateCWImage() -> UIImage? {
        UIImage(systemName: "rotate.right")
    }

    static func clampImage() -> UIImage? {
        UIImage(systemName: "aspectratio")
    }

    static func resetImage() -> UIImage? {
        UIImage(systemName: "arrow.2.circlepath")
    }

    static func alterCropper90DegreeImage() -> UIImage? {
        drawAlterCropper90DegreeImage()
    }

    static func horizontallyFlipImage() -> UIImage? {
        UIImage(systemName: "flip.horizontal")
    }

    static func verticallyFlipImage() -> UIImage? {
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

    static func autoAdjustImage() -> UIImage? {
        UIImage(systemName: "camera.metering.none")
    }
}
