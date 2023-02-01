//
//  MyNavigationCropToolbar.swift
//  MantisExample
//
//  Created by Echo on 7/10/22.
//  Copyright © 2022 Echo. All rights reserved.
//

import Foundation
import Mantis
import UIKit

class MyNavigationCropToolbar: UIView, CropToolbarProtocol {
    var config = CropToolbarConfig()
    
    var heightForVerticalOrientation: CGFloat?
    
    var widthForHorizonOrientation: CGFloat?
    
    var delegate: CropToolbarDelegate?
    
    var iconProvider: CropToolbarIconProvider?
    
    weak var cropViewController: Mantis.CropViewController?
    
    func createToolbarUI(config: CropToolbarConfig) {
        guard let cropViewController = cropViewController else {
            return
        }
        
        cropViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(cancel))
        
        let rotateButton = UIBarButtonItem(image: UIImage(systemName: "rotate.right"), style: .plain, target: self, action: #selector(rotate))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(crop))
        
        cropViewController.navigationItem.rightBarButtonItems = [doneButton, rotateButton]
    }
    
    func handleFixedRatioSetted(ratio: Double) {
        
    }
    
    func handleFixedRatioUnSetted() {
        
    }
    
    @objc func crop() {
        delegate?.didSelectCrop(self)
    }
    
    @objc func cancel() {
        delegate?.didSelectCancel(self)
    }
    
    @objc func rotate() {
        delegate?.didSelectClockwiseRotate(self)
    }
}
