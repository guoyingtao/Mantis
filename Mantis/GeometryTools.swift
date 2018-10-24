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
}
