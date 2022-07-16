//
//  GeometryTools.swift
//  Mantis
//
//  Created by Echo on 10/24/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

enum CropViewOverlayEdge {
    case none
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
}

struct GeometryHelper {    
    static func getInscribeRect(fromOutsideRect outsideRect: CGRect, andInsideRect insideRect: CGRect) -> CGRect {
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
    
    static func getCropEdge(forPoint point: CGPoint, byTouchRect touchRect: CGRect, hotAreaUnit: CGFloat) -> CropViewOverlayEdge {
        // Make sure the corners take priority
        let touchSize = CGSize(width: hotAreaUnit, height: hotAreaUnit)
        
        let topLeftRect = CGRect(origin: touchRect.origin, size: touchSize)
        if topLeftRect.contains(point) { return .topLeft }
        
        let topRightRect = topLeftRect.offsetBy(dx: touchRect.width - hotAreaUnit, dy: 0)
        if topRightRect.contains(point) { return .topRight }
        
        let bottomLeftRect = topLeftRect.offsetBy(dx: 0, dy: touchRect.height - hotAreaUnit)
        if bottomLeftRect.contains(point) { return .bottomLeft }
        
        let bottomRightRect = bottomLeftRect.offsetBy(dx: touchRect.width - hotAreaUnit, dy: 0)
        if bottomRightRect.contains(point) { return .bottomRight }
        
        // Check for edges
        let topRect = CGRect(origin: touchRect.origin, size: CGSize(width: touchRect.width, height: hotAreaUnit))
        if topRect.contains(point) { return .top }
        
        let leftRect = CGRect(origin: touchRect.origin, size: CGSize(width: hotAreaUnit, height: touchRect.height))
        if leftRect.contains(point) { return .left }
        
        let rightRect = CGRect(origin: CGPoint(x: touchRect.maxX - hotAreaUnit,
                                               y: touchRect.origin.y),
                               size: CGSize(width: hotAreaUnit,
                                            height: touchRect.height))
        if rightRect.contains(point) { return .right }
        
        let bottomRect = CGRect(origin: CGPoint(x: touchRect.origin.x,
                                                y: touchRect.maxY - hotAreaUnit),
                                size: CGSize(width: touchRect.width,
                                             height: hotAreaUnit))
        if bottomRect.contains(point) { return .bottom }
        
        return .none
    }
    
    static func scale(from transform: CGAffineTransform) -> Double {
        return sqrt(Double(transform.a * transform.a + transform.c * transform.c))
    }
}
