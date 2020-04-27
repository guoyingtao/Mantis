//
//  CustomizedCropToolBar.swift
//  MantisExample
//
//  Created by Echo on 4/26/20.
//  Copyright © 2020 Echo. All rights reserved.
//

import UIKit
import Mantis

class CustomizedCropToolbar: UIView, CropToolbarProtocol {    
    var optionButtonFontSize: CGFloat = 16
    
    var optionButtonFontSizeForPad: CGFloat = 20
    
    var selectedCancel: () -> Void = {}
    
    var selectedCrop: () -> Void = {}
    
    var selectedRotate: () -> Void = {}
    
    var selectedReset: () -> Void = {}
    
    var selectedSetRatio: () -> Void = {}
    
    var fixedRatioSettingButton: UIButton?
    
    var cropButton: UIButton?
    var cancelButton: UIButton?
    
    var heightForVerticalOrientationConstraint: NSLayoutConstraint?
    var widthForHorizonOrientationConstraint: NSLayoutConstraint?
    
    func createToolbarUI(mode: CropToolbarMode,
                         includeFixedRatioSettingButton: Bool) {
        backgroundColor = .red
        
        cropButton = createOptionButton(withTitle: "Crop", andAction: #selector(crop))
        addSubview(cropButton!)

        cancelButton = createOptionButton(withTitle: "Cancel", andAction: #selector(cancel))
        addSubview(cancelButton!)

        cropButton?.translatesAutoresizingMaskIntoConstraints = false
        cropButton?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        cropButton?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        cropButton?.heightAnchor.constraint(equalToConstant: 40).isActive = true
        cropButton?.widthAnchor.constraint(equalToConstant: 100).isActive = true

        
        cancelButton?.translatesAutoresizingMaskIntoConstraints = false
        cancelButton?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        cancelButton?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        cancelButton?.heightAnchor.constraint(equalToConstant: 40).isActive = true
        cancelButton?.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
            
    @objc private func crop() {
        selectedCrop()
    }
    
    @objc private func cancel() {
        selectedCancel()
    }
    
    private func createOptionButton(withTitle title: String?, andAction action: Selector) -> UIButton {
        let buttonColor = UIColor.white
        let buttonFontSize: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ?
            optionButtonFontSizeForPad :
            optionButtonFontSize
        
        let buttonFont = UIFont.systemFont(ofSize: buttonFontSize)
        
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.titleLabel?.font = buttonFont
        
        if let title = title {
            button.setTitle(title, for: .normal)
            button.setTitleColor(buttonColor, for: .normal)
        }
        
        button.addTarget(self, action: action, for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        
        return button
    }
}
