//
//  CropToolbarProtocol.swift
//  Mantis
//
//  Created by Echo on 4/25/20.
//

import UIKit

public protocol CropToolbarDelegate {
    func didSelectedCancel();
    func didSelectedCrop();
    func didSelectedRotate();
    func didSelectedReset();
    func didSelectedSetRatio();
}

public protocol CropToolbarProtocol: UIView {    
    var heightForVerticalOrientationConstraint: NSLayoutConstraint? {get set}
    var widthForHorizonOrientationConstraint: NSLayoutConstraint? {get set}    
    var cropToolbarDelegate: CropToolbarDelegate? {get set}

    func createToolbarUI(config: CropToolbarConfig)
    
    // MARK: - The following functions have default implementations
    func getRatioListPresentSourceView() -> UIView?
    
    func initConstraints(heightForVerticalOrientation: CGFloat,
                        widthForHorizonOrientation: CGFloat)
    
    func respondToOrientationChange()
    func adjustLayoutConstraintsWhenOrientationChange()
    func adjustUIWhenOrientationChange()
    
    func adjustUIWhenFixedRatioSetted()
    func adjustUIWhenFixedRatioUnSetted()
    
    func handleCropViewDidBecomeResettable()
    func handleCropViewDidBecomeUnResettable()
}

public extension CropToolbarProtocol {
    func getRatioListPresentSourceView() -> UIView? {
        return nil
    }
    
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

    }
    
    func adjustUIWhenFixedRatioUnSetted() {

    }
    
    func handleCropViewDidBecomeResettable() {
        
    }
    
    func handleCropViewDidBecomeUnResettable() {
        
    }
}
