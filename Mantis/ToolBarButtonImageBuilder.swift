//
//  ToolBarButtonImageBuilder.swift
//  Mantis
//
//  Created by Echo on 11/6/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

struct ToolBarButtonImageBuilder {
    static func rotateCCWImage() -> UIImage? {
        var rotateImage: UIImage? = nil
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 18, height: 21), false, 0.0)
        
        //// Rectangle 2 Drawing
        let rectangle2Path = UIBezierPath(rect: CGRect(x: 0, y: 9, width: 12, height: 12))
        UIColor.white.setFill()
        rectangle2Path.fill()
        
        //// Rectangle 3 Drawing
        let rectangle3Path = UIBezierPath()
        rectangle3Path.move(to: CGPoint(x: 5, y: 3))
        rectangle3Path.addLine(to: CGPoint(x: 10, y: 6))
        rectangle3Path.addLine(to: CGPoint(x: 10, y: 0))
        rectangle3Path.addLine(to: CGPoint(x: 5, y: 3))
        rectangle3Path.close()
        UIColor.white.setFill()
        rectangle3Path.fill()
        
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
    
    static func rotateCWImage() -> UIImage? {
        guard let rotateCCWImage = self.rotateCCWImage(), let cgImage = rotateCCWImage.cgImage else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(rotateCCWImage.size, false,  rotateCCWImage.scale )
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: rotateCCWImage.size.width, y: rotateCCWImage.size.height)
        context?.rotate(by: .pi)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: rotateCCWImage.size.width, height: rotateCCWImage.size.height))
        let rotateCWImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotateCWImage
    }
    
    static func clampImage() -> UIImage? {
        var clampImage: UIImage? = nil
        
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
}
