//
//  RotationDialProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import UIKit

@MainActor
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
     - Return true when the value does not exceeds the limitation or there is no limitation
     - Return false when the value exceeds the limitation
     */
    @discardableResult func updateRotationValue(by angle: Angle) -> Bool
    
    /**
     Reset rotation control view to initial status
     */
    func reset()
    
    /**
     If you need to adjust UI when rotationg device, implement this function.
     Otherwise not.
     */
    func handleDeviceRotation()
        
    // MARK: If isAttachedToCropView is true, implement functions below
    /**
     The allowableFrame is set by CropView.
     No need to implement it if isAttachedToCropView is false
     */
    func setupUI(withAllowableFrame allowableFrame: CGRect)
    
    /**
     Handle touch target when user touchs the crop view area
     No need to implement it if isAttachedToCropView is false
     */
    func getTouchTarget(with point: CGPoint) -> UIView
        
    /**
     It sets the size ratio comparing rotation control view with the crop view.
     No need to implement it if isAttachedToCropView is false
     */
    func getLengthRatio() -> CGFloat
    
    /**
     Set accessibilities of the view which includes accessibilityTraits, accessibilityLabel and accessibilityValue
     */
    func setAccessibilities()
    
    /**
     Set accessibilityValue of the view
     */
    func setAccessibilityValue()
    
    /**
     Get total rotation value of the dial. (Unit: degree)
     */
    func getTotalRotationValue() -> CGFloat
}

public extension RotationControlViewProtocol {
    func setupUI(withAllowableFrame allowableFrame: CGRect) {}
    func getTouchTarget(with point: CGPoint) -> UIView {
        return self
    }
    
    func handleDeviceRotation() {}
    
    func getLengthRatio() -> CGFloat {
        return 0.6
    }
    
    func setAccessibilities() {
        isAccessibilityElement = true
        accessibilityTraits = .adjustable
        accessibilityLabel = LocalizedHelper.getString("Mantis.Adjust image angle", value: "Adjust image angle")
        setAccessibilityValue()
    }
    
    func setAccessibilityValue() {
        accessibilityValue = accessibilityDegreesText()
    }
}

extension RotationControlViewProtocol {
    /// The rounded rotation value as VoiceOver reads it, e.g. "1 degree" or "-5 degrees"
    func accessibilityDegreesText() -> String {
        let degreeValue = Int(round(getTotalRotationValue()))
        let unit = abs(degreeValue) == 1 ? "degree" : "degrees"
        return "\(degreeValue) \(unit)"
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
