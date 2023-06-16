//
//  RotationDialProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import UIKit

public protocol RotationControlViewProtocol: UIView {
    /**
     Set it to true if you want CropView to control the frame of your own rotation control view.
     Otherwise set it to false
     */
    var isAttachedToCropView: Bool { get set }
    
    /**
     It should be called every time updating the roation value by your own rotaion control view
     */
    var didUpdateRotationValue: (_ angle: Angle) -> Void { get set }
    
    /**
     It should be called every time updating the rotation value by your own roation conrol view is done
     */
    var didFinishRotation: () -> Void { get set }
    
    /**
     The allowableFrame is set by CropView. No need to implement it if isAttachedToCropView is false
     */
    func setupUI(withAllowableFrame allowableFrame: CGRect)
    
    /**
     - Return true when the value does not exceeds the limitation or there is no limitation
     - Return false when the value exceeds the limitation
     */
    @discardableResult func updateRotationValue(by angle: Angle) -> Bool
    
    /**
     Reset rotation control view to initial status
     */
    func reset()
    
    func getTouchTarget() -> UIView
}

extension RotationControlViewProtocol {
    func setupUI(withAllowableFrame allowableFrame: CGRect) {}
    func getTouchTarget() -> UIView {
        return self
    }
}

protocol RotationDialProtocol: RotationControlViewProtocol {
    var pointerHeight: CGFloat { get set }
    var spanBetweenDialPlateAndPointer: CGFloat { get set }
    var pointerWidth: CGFloat { get set }
    
    func setRotationCenter(by point: CGPoint, of view: UIView)
    func rotateDialPlate(to angle: Angle, animated: Bool)
    func getRotationAngle() -> Angle
}
