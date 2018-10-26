//
//  GeometryTools.swift
//  Mantis
//
//  Created by Echo on 10/24/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

struct GeometryTools {
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
    
    static func checkIf(outerView: UIView, coveredInnerView innerView: UIView) -> Bool {
        let p1 = innerView.convert(CGPoint(x: 0, y: 0), to: outerView)
        let p2 = innerView.convert(CGPoint(x: innerView.frame.width, y: 0), to: outerView)
        let p3 = innerView.convert(CGPoint(x: 0, y: innerView.frame.height), to: outerView)
        let p4 = innerView.convert(CGPoint(x: innerView.frame.width, y: innerView.frame.height), to: outerView)
        
        print("p list is \(p1) \(p2) \(p3) \(p4)")
        
        if outerView.bounds.contains(p1) && outerView.bounds.contains(p2) && outerView.bounds.contains(p3) && outerView.bounds.contains(p4) {
            return true
        }
        
        return false
    }
}
