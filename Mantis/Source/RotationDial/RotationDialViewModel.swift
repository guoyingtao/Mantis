//
//  RotationDialViewModel.swift
//  Puffer
//
//  Created by Echo on 5/22/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import UIKit

public class RotationDialViewModel: NSObject {
    fileprivate var rotationCal: RotationCalculator?    
    @objc dynamic var rotationAngle = CGAngle(degrees: 0)
    
    var touchPoint: CGPoint? {
        didSet {
            guard let oldValue = oldValue,
                let newValue = self.touchPoint,
                let rotationCal = rotationCal else {
                return
            }
            
            let radians = rotationCal.getRotationRadians(byOldPoint: oldValue, andNewPoint: newValue)
            rotationAngle = CGAngle(radians: radians)
        }
    }
    
    public override init() {
        
    }
    
    func makeRotationCalculator(by midPoint: CGPoint) {
        rotationCal = RotationCalculator(midPoint: midPoint)
    }
}
