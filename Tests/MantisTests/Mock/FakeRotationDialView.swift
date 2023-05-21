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
    
    var didRotate: (Angle) -> Void = { _ in }
    
    var didFinishedRotate: () -> Void = { }
    
    func setup(with frame: CGRect) {
        
    }
    
    func rotateDialPlate(by angle: Angle) -> Bool {
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
