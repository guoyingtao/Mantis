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
    var config: CropToolbarConfigProtocol?
    
    var heightForVerticalOrientation: CGFloat?
    
    var widthForHorizonOrientation: CGFloat?
    
    var cropToolbarDelegate: CropToolbarDelegate?
    
    var iconProvider: CropToolbarIconProvider?
    
    weak var cropViewController: Mantis.CropViewController?
    
    func createToolbarUI(config: CropToolbarConfigProtocol?) {
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
        cropToolbarDelegate?.didSelectCrop()
    }
    
    @objc func cancel() {
        cropToolbarDelegate?.didSelectCancel()
    }
    
    @objc func rotate() {
        cropToolbarDelegate?.didSelectClockwiseRotate()
    }
}
