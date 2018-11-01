//
//  ImageStatus.swift
//  Mantis
//
//  Created by Echo on 10/26/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

enum ImageRotationType: CGFloat {
    case none = 0
    case anticlockwise90 = -90
    case anticlockwise180 = -180
    case anticlockwise270 = -270
    
    mutating func anticlockwiseRotate90() {
        if self == .anticlockwise270 {
            self = .none
        } else {
            self = ImageRotationType(rawValue: self.rawValue - 90) ?? .none
        }
    }
}

struct ImageStatus {
    var degrees: CGFloat = 0
    
    var radians: CGFloat {
        get {
          return degrees * CGFloat.pi / 180
        }
    }
    
    var zoomScale: CGFloat = 0
    var offset: CGPoint = .zero
    var rotationType: ImageRotationType = .none
    
    mutating func reset() {
        degrees = 0
        zoomScale = 0
        offset = .zero
        rotationType = .none
    }
    
    mutating func anticlockwiseRotate90() {
        rotationType.anticlockwiseRotate90()
    }
    
    mutating func getTotalRadians() -> CGFloat {
        return radians + rotationType.rawValue * CGFloat.pi / 180
    }
}
