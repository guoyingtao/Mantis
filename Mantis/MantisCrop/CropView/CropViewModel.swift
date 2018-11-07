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
    case counterclockwise90 = -90
    case counterclockwise180 = -180
    case counterclockwise270 = -270
    
    mutating func counterclockwiseRotate90() {
        if self == .counterclockwise270 {
            self = .none
        } else {
            self = ImageRotationType(rawValue: self.rawValue - 90) ?? .none
        }
    }
}

struct CropViewModel {
    
    var degrees: CGFloat = 0
    
    var radians: CGFloat {
        get {
          return degrees * CGFloat.pi / 180
        }
    }
    
    var rotationType: ImageRotationType = .none
    var aspectRatio: CGFloat = -1    
    var cropLeftTopOnImage: CGPoint = .zero
    var cropRightBottomOnImage: CGPoint = CGPoint(x: 1, y: 1)
    
    mutating func reset() {
        degrees = 0
        rotationType = .none
        aspectRatio = -1
        
        cropLeftTopOnImage = .zero
        cropRightBottomOnImage = CGPoint(x: 1, y: 1)
    }
    
    mutating func counterclockwiseRotate90() {
        rotationType.counterclockwiseRotate90()
    }
    
    func getTotalRadians() -> CGFloat {
        return radians + rotationType.rawValue * CGFloat.pi / 180
    }    
}
