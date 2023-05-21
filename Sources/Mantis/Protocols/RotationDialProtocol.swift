//
//  RotationDialProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import UIKit

public protocol RotationControlViewProtocol: UIView {
    var beingRotated: (_ realtimeAngle: Angle) -> Void { get set }
    var didFinishRotation: () -> Void { get set }
    
    func setupUI(with frame: CGRect)
    
    /**
        Return false when the value is more than limitation
     */
    @discardableResult func updateRotationValue(by angle: Angle) -> Bool
    
    /**
        Reset rotation view to initial status
     */
    func reset()
}

protocol RotationDialProtocol: RotationControlViewProtocol {
    var pointerHeight: CGFloat { get set }
    var spanBetweenDialPlateAndPointer: CGFloat { get set }
    var pointerWidth: CGFloat { get set }
    
    func setRotationCenter(by point: CGPoint, of view: UIView)
    func rotateDialPlate(to angle: Angle, animated: Bool)
    func getRotationAngle() -> Angle
}
