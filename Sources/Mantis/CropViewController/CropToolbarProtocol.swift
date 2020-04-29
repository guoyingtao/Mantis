//
//  CropToolbarProtocol.swift
//  Mantis
//
//  Created by Echo on 4/25/20.
//

import UIKit

public protocol CropToolbarProtocol: UIView {
    var optionButtonFontSize: CGFloat {get set}
    var optionButtonFontSizeForPad: CGFloat {get set}
    
    var selectedCancel: ()->Void {get set}
    var selectedCrop: ()->Void {get set}
    var selectedRotate: ()->Void {get set}
    var selectedReset: ()->Void {get set}
    var selectedSetRatio: ()->Void {get set}
    
    var fixedRatioSettingButton: UIButton? {get set}
    var heightForVerticalOrientationConstraint: NSLayoutConstraint? {get set}
    var widthForHorizonOrientationConstraint: NSLayoutConstraint? {get set}

    func createToolbarUI(mode: CropToolbarMode,
                         includeFixedRatioSettingButton: Bool)
    
    // MARK: - The following functions have default implementations
    func initConstraints(heightForVerticalOrientation: CGFloat,
                        widthForHorizonOrientation: CGFloat)
    
    func respondToOrientationChange()
    func adjustLayoutConstraintsWhenOrientationChange()
    func adjustUIWhenOrientationChange()
    
    func adjustUIWhenFixedRatioSetted()
    func adjustUIWhenRatioResetted()
    
    func handleCropViewDidBecomeResettable()
    func handleCropViewDidBecomeNonResettable()
}

public extension CropToolbarProtocol {
    func initConstraints(heightForVerticalOrientation: CGFloat, widthForHorizonOrientation: CGFloat) {
        heightForVerticalOrientationConstraint = heightAnchor.constraint(equalToConstant: heightForVerticalOrientation)
        widthForHorizonOrientationConstraint = widthAnchor.constraint(equalToConstant: widthForHorizonOrientation)
    }
    
    func respondToOrientationChange() {
        adjustLayoutConstraintsWhenOrientationChange()
        adjustUIWhenOrientationChange()
    }
    
    func adjustLayoutConstraintsWhenOrientationChange() {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            heightForVerticalOrientationConstraint?.isActive = true
            widthForHorizonOrientationConstraint?.isActive = false
        } else {
            heightForVerticalOrientationConstraint?.isActive = false
            widthForHorizonOrientationConstraint?.isActive = true
        }
    }
    
    func adjustUIWhenOrientationChange() {
        
    }
    
    func adjustUIWhenFixedRatioSetted() {
        fixedRatioSettingButton?.tintColor = nil
    }
    
    func adjustUIWhenRatioResetted() {
        fixedRatioSettingButton?.tintColor = .white
    }
    
    func handleCropViewDidBecomeResettable() {
        
    }
    
    func handleCropViewDidBecomeNonResettable() {
        
    }
}
