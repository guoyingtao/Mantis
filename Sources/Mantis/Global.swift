//
//  Global.swift
//  Mantis
//
//  Created by yingtguo on 7/17/22.
//

import Foundation

func print(_ objects: Any...) {
    #if DEBUG
    for item in objects {
        Swift.print(item)
    }
    #endif
}

func print(_ object: Any) {
    #if DEBUG
    Swift.print(object)
    #endif
}

func isTheSamePoint(point1: CGPoint, point2: CGPoint) -> Bool {
    let tolerance = CGFloat.ulpOfOne * 10
    if abs(point1.x - point2.x) > tolerance { return false }
    if abs(point1.y - point2.y) > tolerance { return false }
    
    return true
}
