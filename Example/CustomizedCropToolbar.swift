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
    var stackView: UIStackView?
    
    func createToolbarUI(mode: CropToolbarMode,
                         includeFixedRatioSettingButton: Bool) {
        backgroundColor = .red
        
        cropButton = createOptionButton(withTitle: "Crop", andAction: #selector(crop))

        cancelButton = createOptionButton(withTitle: "Cancel", andAction: #selector(cancel))
        
        stackView = UIStackView()
        addSubview(stackView!)
        
        stackView?.translatesAutoresizingMaskIntoConstraints = false
        stackView?.alignment = .center
        stackView?.distribution = .fillEqually
        
        stackView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        stackView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stackView?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stackView?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        stackView?.addArrangedSubview(cancelButton!)
        stackView?.addArrangedSubview(cropButton!)
    }
    
    func adjustUIForOrientation() {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            heightForVerticalOrientationConstraint?.isActive = true
            widthForHorizonOrientationConstraint?.isActive = false
            stackView?.axis = .horizontal
        } else {
            heightForVerticalOrientationConstraint?.isActive = false
            widthForHorizonOrientationConstraint?.isActive = true
            stackView?.axis = .vertical
        }
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
