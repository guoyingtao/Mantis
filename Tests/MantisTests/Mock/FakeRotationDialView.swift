//
//  FakeRotationDialView.swift
//  Mantis
//
//  Created by Yingtao Guo on 2/3/23.
//

import UIKit
@testable import Mantis

class FakeRotationDialView: UIView, RotationDialProtocol {
    var pointerHeight: CGFloat = 0
    
    var spanBetweenDialPlateAndPointer: CGFloat = 0
    
    var pointerWidth: CGFloat = 0
    
    var beingRotated: (Angle) -> Void = { _ in }
    
    var didFinishRotation: () -> Void = { }
    
    func setupUI(with frame: CGRect) {
        
    }
    
    func updateRotationValue(by angle: Angle) -> Bool {
        false
    }
    
    func rotateDialPlate(to angle: Angle, animated: Bool) {
        
    }
    
    func getRotationAngle() -> Angle {
        .init(degrees: 0)
    }
    
    func setRotationCenter(by point: CGPoint, of view: UIView) {
        
    }
    
    func reset() {
        
    }
}
