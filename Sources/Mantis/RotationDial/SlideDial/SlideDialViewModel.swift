//
//  SlideDialViewModel.swift
//  Mantis
//
//  Created by Yingtao Guo on 6/19/23.
//

import Foundation

final class SlideDialViewModel {
    var didSetRotationAngle: (Angle) -> Void = { _ in }
    
    var rotationAngle = Angle(degrees: 0) {
        didSet {
            didSetRotationAngle(rotationAngle)
        }
    }
    
    func reset() {
        rotationAngle = Angle(degrees: 0)
    }
}
