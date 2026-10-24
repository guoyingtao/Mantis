//
//  FakeCropToolbar.swift
//  Mantis
//
//  Created by Yingtao Guo on 2/2/23.
//

import UIKit
@testable import Mantis

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
    var fixedRatiosSetted: [Double] = []
    var ratioListPresentSourceView: UIView?

    func createToolbarUI(config: CropToolbarConfig) {
        self.config = config
    }

    func getRatioListPresentSourceView() -> UIView? {
        ratioListPresentSourceView
    }

    func handleFixedRatioSetted(ratio: Double) {
        didHandleFixedRatioSetted = true
        fixedRatiosSetted.append(ratio)
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
