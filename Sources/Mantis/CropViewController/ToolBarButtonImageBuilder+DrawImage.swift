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

extension ToolBarButtonImageBuilder {
    static func drawRotateCCWImage() -> UIImage? {
        var rotateImage: UIImage?
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 18, height: 21), false, 0.0)
        
        //// Draw rectangle
        let rectanglePath = UIBezierPath(rect: CGRect(x: 0, y: 9, width: 12, height: 12))
        UIColor.white.setFill()
        rectanglePath.fill()
        
        //// Draw triangle
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x: 5, y: 3))
        trianglePath.addLine(to: CGPoint(x: 10, y: 6))
        trianglePath.addLine(to: CGPoint(x: 10, y: 0))
        trianglePath.addLine(to: CGPoint(x: 5, y: 3))
        trianglePath.close()
        UIColor.white.setFill()
        trianglePath.fill()
        
        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 10, y: 3))
        
        bezierPath.addCurve(to: CGPoint(x: 17.5, y: 11), controlPoint1: CGPoint(x: 15, y: 3), controlPoint2: CGPoint(x: 17.5, y: 5.91))
        UIColor.white.setStroke()
        bezierPath.lineWidth = 1
        bezierPath.stroke()
        rotateImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return rotateImage
    }
    
    static func drawRotateCWImage() -> UIImage? {
        guard let rotateCCWImage = self.rotateCCWImage(), let cgImage = rotateCCWImage.cgImage else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(rotateCCWImage.size, false, rotateCCWImage.scale )
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: rotateCCWImage.size.width, y: rotateCCWImage.size.height)
        context?.rotate(by: .pi)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: rotateCCWImage.size.width, height: rotateCCWImage.size.height))
        let rotateCWImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotateCWImage
    }
    
    static func drawFlipHorizontally() -> UIImage? {
        var flippedImage: UIImage?
        
        let wholeWidth = 24
        let wholeHeight = 24
        UIGraphicsBeginImageContextWithOptions(CGSize(width: wholeWidth, height: wholeHeight), false, 0.0)
        
        let arrowWidth = 5
        let arrowHeight = 6
        let topbarWidth = wholeWidth - arrowWidth
        let topbarY = arrowHeight / 2 - 1
        
        // topbar
        let rectangle2Path = UIBezierPath(rect: CGRect(x: 0, y: topbarY, width: topbarWidth, height: 1))
        UIColor.white.setFill()
        rectangle2Path.fill()
        
        // left arrow
        let leftarrowPath = UIBezierPath()
        leftarrowPath.move(to: CGPoint(x: 0, y: topbarY))
        leftarrowPath.addLine(to: CGPoint(x: arrowWidth, y: 0))
        leftarrowPath.addLine(to: CGPoint(x: arrowWidth, y: arrowHeight))
        leftarrowPath.addLine(to: CGPoint(x: 0, y: topbarY))
        leftarrowPath.close()
        UIColor.white.setFill()
        leftarrowPath.fill()
        
        // right arrow
        let rightarrowPath = UIBezierPath()
        rightarrowPath.move(to: CGPoint(x: wholeWidth, y: topbarY))
        rightarrowPath.addLine(to: CGPoint(x: wholeWidth - arrowWidth, y: 0))
        rightarrowPath.addLine(to: CGPoint(x: wholeWidth - arrowWidth, y: arrowHeight))
        rightarrowPath.addLine(to: CGPoint(x: wholeWidth, y: topbarY))
        rightarrowPath.close()
        UIColor.white.setFill()
        rightarrowPath.fill()
        
        let mirrorWidth = wholeWidth / 2 - 1
        let mirrowHeight = wholeHeight - 8
        
        // left mirror
        let leftMirror = UIBezierPath()
        leftMirror.move(to: CGPoint(x: 0, y: wholeHeight))
        leftMirror.addLine(to: CGPoint(x: mirrorWidth, y: wholeHeight))
        leftMirror.addLine(to: CGPoint(x: mirrorWidth, y: wholeHeight - mirrowHeight))
        leftMirror.addLine(to: CGPoint(x: 0, y: wholeHeight))
        leftMirror.close()
        UIColor.white.setFill()
        leftMirror.fill()
        
        // right mirror
        let rightMirror = UIBezierPath()
        rightMirror.move(to: CGPoint(x: wholeWidth, y: wholeHeight))
        rightMirror.addLine(to: CGPoint(x: wholeWidth - mirrorWidth, y: wholeHeight))
        rightMirror.addLine(to: CGPoint(x: wholeWidth - mirrorWidth, y: wholeHeight - mirrowHeight))
        rightMirror.addLine(to: CGPoint(x: wholeWidth, y: wholeHeight))
        rightMirror.close()
        UIColor.white.setFill()
        rightMirror.fill()
        
        flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return flippedImage
        
    }
    
    static func drawFlipVertically() -> UIImage? {
        guard let flippedHorizontallyImage = self.flipHorizontally(), let cgImage = flippedHorizontallyImage.cgImage else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(flippedHorizontallyImage.size, false, flippedHorizontallyImage.scale )
        let context = UIGraphicsGetCurrentContext()
        context?.rotate(by: -.pi / 2)
        context?.translateBy(x: -flippedHorizontallyImage.size.height, y: 0)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: flippedHorizontallyImage.size.height, height: flippedHorizontallyImage.size.width))
        let fippedVerticallyImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return fippedVerticallyImage
    }
    
    static func drawClampImage() -> UIImage? {
        var clampImage: UIImage?
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 22, height: 16), false, 0.0)
        
        //// Color Declarations
        let outerBox = UIColor(red: 1, green: 1, blue: 1, alpha: 0.553)
        let innerBox = UIColor(red: 1, green: 1, blue: 1, alpha: 0.773)
        
        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRect(x: 0, y: 3, width: 13, height: 13))
        UIColor.white.setFill()
        rectanglePath.fill()
        
        //// Outer
        //// Top Drawing
        let topPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 22, height: 2))
        outerBox.setFill()
        topPath.fill()
        
        //// Side Drawing
        let sidePath = UIBezierPath(rect: CGRect(x: 19, y: 2, width: 3, height: 14))
        outerBox.setFill()
        sidePath.fill()
        
        //// Rectangle 2 Drawing
        let rectangle2Path = UIBezierPath(rect: CGRect(x: 14, y: 3, width: 4, height: 13))
        innerBox.setFill()
        rectangle2Path.fill()
        
        clampImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return clampImage
    }
    
    static func drawResetImage() -> UIImage? {
        var resetImage: UIImage?
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 22, height: 18), false, 0.0)            //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 22, y: 9))
        bezier2Path.addCurve(to: CGPoint(x: 13, y: 18), controlPoint1: CGPoint(x: 22, y: 13.97), controlPoint2: CGPoint(x: 17.97, y: 18))
        bezier2Path.addCurve(to: CGPoint(x: 13, y: 16), controlPoint1: CGPoint(x: 13, y: 17.35), controlPoint2: CGPoint(x: 13, y: 16.68))
        bezier2Path.addCurve(to: CGPoint(x: 20, y: 9), controlPoint1: CGPoint(x: 16.87, y: 16), controlPoint2: CGPoint(x: 20, y: 12.87))
        bezier2Path.addCurve(to: CGPoint(x: 13, y: 2), controlPoint1: CGPoint(x: 20, y: 5.13), controlPoint2: CGPoint(x: 16.87, y: 2))
        bezier2Path.addCurve(to: CGPoint(x: 6.55, y: 6.27), controlPoint1: CGPoint(x: 10.1, y: 2), controlPoint2: CGPoint(x: 7.62, y: 3.76))
        bezier2Path.addCurve(to: CGPoint(x: 6, y: 9), controlPoint1: CGPoint(x: 6.2, y: 7.11), controlPoint2: CGPoint(x: 6, y: 8.03))
        bezier2Path.addLine(to: CGPoint(x: 4, y: 9))
        bezier2Path.addCurve(to: CGPoint(x: 4.65, y: 5.63), controlPoint1: CGPoint(x: 4, y: 7.81), controlPoint2: CGPoint(x: 4.23, y: 6.67))
        bezier2Path.addCurve(to: CGPoint(x: 7.65, y: 1.76), controlPoint1: CGPoint(x: 5.28, y: 4.08), controlPoint2: CGPoint(x: 6.32, y: 2.74))
        bezier2Path.addCurve(to: CGPoint(x: 13, y: 0), controlPoint1: CGPoint(x: 9.15, y: 0.65), controlPoint2: CGPoint(x: 11, y: 0))
        bezier2Path.addCurve(to: CGPoint(x: 22, y: 9), controlPoint1: CGPoint(x: 17.97, y: 0), controlPoint2: CGPoint(x: 22, y: 4.03))
        bezier2Path.close()
        UIColor.white.setFill()
        bezier2Path.fill()
        
        //// Polygon Drawing
        let polygonPath = UIBezierPath()
        polygonPath.move(to: CGPoint(x: 5, y: 15))
        polygonPath.addLine(to: CGPoint(x: 10, y: 9))
        polygonPath.addLine(to: CGPoint(x: 0, y: 9))
        polygonPath.addLine(to: CGPoint(x: 5, y: 15))
        polygonPath.close()
        UIColor.white.setFill()
        polygonPath.fill()
        
        resetImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resetImage
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
