//
//  FakeCropToolbar.swift
//  Mantis
//
//  Created by yingtguo on 2/2/23.
//

import UIKit

class FakeCropToolbar: UIView, CropToolbarProtocol {
    var config = CropToolbarConfig()
    
    var delegate: CropToolbarDelegate?
    var iconProvider: CropToolbarIconProvider?
    
    var didHandleFixedRatioSetted = false
    var didHandleFixedRatioUnSetted = false
    var didRespondToOrientationChange = false
    var didAdjustLayoutWhenOrientationChange = false
    var didHandleCropViewDidBecomeResettable = false
    var didHandleCropViewDidBecomeUnResettable = false
    
    func createToolbarUI(config: CropToolbarConfig) {
        self.config = config
    }
    
    func handleFixedRatioSetted(ratio: Double) {
        didHandleFixedRatioSetted = true
    }
    
    func handleFixedRatioUnSetted() {
        didHandleFixedRatioUnSetted = true        
    }
    
    func respondToOrientationChange() {
        didRespondToOrientationChange = true
    }
    
    func adjustLayoutWhenOrientationChange() {
        didAdjustLayoutWhenOrientationChange = true
    }
    
    func handleCropViewDidBecomeResettable() {
        didHandleCropViewDidBecomeResettable = true
    }
    
    func handleCropViewDidBecomeUnResettable() {
        didHandleCropViewDidBecomeUnResettable = true
    }
}
