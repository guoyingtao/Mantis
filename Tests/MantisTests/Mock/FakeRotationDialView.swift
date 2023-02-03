//
//  FakeRotationDialView.swift
//  Mantis
//
//  Created by Yingtao Guo on 2/3/23.
//

import UIKit

class FakeRotationDialView: UIView, RotationDialProtocol {
    var pointerHeight: CGFloat = 0
    
    var spanBetweenDialPlateAndPointer: CGFloat = 0
    
    var pointerWidth: CGFloat = 0
    
    var didRotate: (CGAngle) -> Void = { _ in }
    
    var didFinishedRotate: () -> Void = { }
    
    func setup(with frame: CGRect) {
        
    }
    
    func rotateDialPlate(by angle: CGAngle) -> Bool {
        false
    }
    
    func rotateDialPlate(to angle: CGAngle, animated: Bool) {
        
    }
    
    func resetAngle(animated: Bool) {
        
    }
    
    func getRotationAngle() -> CGAngle {
        .init(degrees: 0)
    }
    
    func setRotationCenter(by point: CGPoint, of view: UIView) {
        
    }
    
    func reset() {
        
    }
}
