//
//  ToolBarButtonImageBuilder+DrawImage.swift
//  Mantis
//
//  Created by Echo on 07/11/22.
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

// Hand-drawn fallbacks for toolbar icons that have no SF Symbol equivalent.
// The rest of the icons use `UIImage(systemName:)` directly (see
// ToolBarButtonImageBuilder), which is always available on the iOS 15 minimum.
extension ToolBarButtonImageBuilder {
    static func drawFlipVertically() -> UIImage? {
        guard let flippedHorizontallyImage = self.flipHorizontally(), let cgImage = flippedHorizontallyImage.cgImage else { return nil }

        UIGraphicsBeginImageContextWithOptions(flippedHorizontallyImage.size, false, flippedHorizontallyImage.scale )
        let context = UIGraphicsGetCurrentContext()
        context?.rotate(by: -.pi / 2)
        context?.translateBy(x: -flippedHorizontallyImage.size.height, y: 0)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: flippedHorizontallyImage.size.height, height: flippedHorizontallyImage.size.width))
        let flippedVerticallyImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flippedVerticallyImage
    }

    static func drawAlterCropper90DegreeImage() -> UIImage? {
        var rotateCropperImage: UIImage?

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 22, height: 22), false, 0.0)

        //// Draw rectangle
        let rectanglePath1 = UIBezierPath(rect: CGRect(x: 1, y: 5, width: 20, height: 11))
        UIColor.white.setStroke()
        rectanglePath1.lineWidth = 1
        rectanglePath1.stroke()

        let rectanglePath2 = UIBezierPath(rect: CGRect(x: 6, y: 1, width: 10, height: 20))
        UIColor.white.setStroke()
        rectanglePath2.lineWidth = 1
        rectanglePath2.stroke()

        rotateCropperImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return rotateCropperImage
    }
}
