//
//  GeometryTools.swift
//  Mantis
//
//  Created by Echo on 10/24/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

struct GeometryHelper {
    static func getIncribeRect(fromOutsideRect outsideRect: CGRect, andInsideRect insideRect: CGRect) -> CGRect {
        let insideRectRatio = insideRect.width / insideRect.height
        let outsideRectRatio = outsideRect.width / outsideRect.height
        
        var rect = CGRect(origin: .zero, size: insideRect.size)
        if outsideRectRatio > insideRectRatio {
            rect.size.width *= outsideRect.height / rect.height
            rect.size.height = outsideRect.height
        } else {
            rect.size.height *= outsideRect.width / rect.width
            rect.size.width = outsideRect.width
        }
        
        rect.origin.x = outsideRect.midX - rect.width / 2
        rect.origin.y = outsideRect.midY - rect.height / 2
        return rect
    }
    
    static func getOverSteppedCornerPoints(from outerView: UIView, andeInnerView innerView: UIView) -> [CGPoint] {
        let p1 = innerView.convert(CGPoint(x: 0, y: 0), to: outerView)
        let p2 = innerView.convert(CGPoint(x: innerView.bounds.width, y: 0), to: outerView)
        let p3 = innerView.convert(CGPoint(x: 0, y: innerView.bounds.height), to:  outerView)
        let p4 = innerView.convert(CGPoint(x: innerView.bounds.width, y: innerView.frame.height), to: outerView)
        
        let points = [p1, p2, p3, p4]
        var outsidePoints: [CGPoint] = []
        
        for p in points {
            if !outerView.bounds.contains(p) {
                outsidePoints.append(p)
            }
        }
        
        return outsidePoints
    }
    
    static func getMiddlePoint(of p1: CGPoint, and p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
}
