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
    
    func createToolbarUI(mode: CropToolbarMode, includeFixedRatioSettingButton: Bool)
    
    func adjustUIForOrientation()
    func handleCropViewDidBecomeResettable()
    func handleCropViewDidBecomeNonResettable()
}

extension CropToolbarProtocol {
    func adjustUIForOrientation() {
        
    }
    
    func handleCropViewDidBecomeResettable() {
        
    }
    
    func handleCropViewDidBecomeNonResettable() {
        
    }
}
