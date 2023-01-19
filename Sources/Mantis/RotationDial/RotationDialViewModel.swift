//
//  RotationDialViewModel.swift
//  Puffer
//
//  Created by Echo on 5/22/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import UIKit

class RotationDialViewModel: RotationDialViewModelProtocol {
    var didSetRotationAngle: (CGAngle) -> Void = { _ in }
    
    var touchPoint: CGPoint? {
        didSet {
            guard let oldValue = oldValue,
                let newValue = self.touchPoint,
                let rotationCal = rotationCalculator else {
                return
            }
            
            let radians = rotationCal.getRotationRadians(byOldPoint: oldValue, andNewPoint: newValue)
            rotationAngle = CGAngle(radians: radians)
        }
    }

    private var rotationAngle = CGAngle(degrees: 0) {
        didSet {
            didSetRotationAngle(rotationAngle)
        }
    }

    private var rotationCalculator: RotationCalculator?
    
    func setup(with midPoint: CGPoint) {
        rotationCalculator = RotationCalculator(midPoint: midPoint)
    }
}
