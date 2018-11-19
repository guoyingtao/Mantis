//
//  CropToolbar.swift
//  Mantis
//
//  Created by Echo on 11/6/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

public enum CropToolbarMode {
    case normal
    case simple
}

class CropToolbar: UIView {    
    var selectedCancel = {}
    var selectedCrop = {}
    var selectedRotate = {}
    var selectedReset = {}
    var selectedSetRatio = {}
    
    var cancelButton: UIButton?
    var setRatioButton: UIButton?
    var resetButton: UIButton?
    var anticlockRotateButton: UIButton?
    var cropButton: UIButton?
    
    private var optionButtonStackView: UIStackView?
    
    private func createOptionButton(withTitle title: String?, andAction action: Selector) -> UIButton {
        let buttonColor = UIColor.white
        let buttonFontSize: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 20 : 14
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
    
    private func createCancelButton() {
        let cancelText = LocalizedHelper.getString("Cancel")
        
        cancelButton = createOptionButton(withTitle: cancelText, andAction: #selector(cancel))
    }
    
    private func createRotationButton() {
        anticlockRotateButton = createOptionButton(withTitle: nil, andAction: #selector(rotate))
        anticlockRotateButton?.setImage(ToolBarButtonImageBuilder.rotateCCWImage(), for: .normal)
    }
    
    private func createResetButton(with image: UIImage? = nil) {
        if let image = image {
            resetButton = createOptionButton(withTitle: nil, andAction: #selector(reset))
            resetButton?.setImage(image, for: .normal)
        } else {
            let resetText = LocalizedHelper.getString("Reset")

            resetButton = createOptionButton(withTitle: resetText, andAction: #selector(reset))
        }
    }
    
    private func createSetRatioButton() {
        setRatioButton = createOptionButton(withTitle: nil, andAction: #selector(setRatio))
        setRatioButton?.setImage(ToolBarButtonImageBuilder.clampImage(), for: .normal)
    }
    
    private func createCropButton() {
        let doneText = LocalizedHelper.getString("Done")
        cropButton = createOptionButton(withTitle: doneText, andAction: #selector(crop))
    }
    
    private func createButtonContainer() {
        optionButtonStackView = UIStackView()
        addSubview(optionButtonStackView!)
        
        optionButtonStackView?.distribution = .equalCentering
        optionButtonStackView?.isLayoutMarginsRelativeArrangement = true
    }
    
    private func setButtonContainerLayout() {
        optionButtonStackView?.translatesAutoresizingMaskIntoConstraints = false
        optionButtonStackView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionButtonStackView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        optionButtonStackView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        optionButtonStackView?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    private func addButtonsToContainer(buttons: [UIButton?]) {
        buttons.forEach{
            if let button = $0 {
                optionButtonStackView?.addArrangedSubview(button)
            }
        }
    }
    
    func createToolbarUI(mode: CropToolbarMode = .normal) {
        createButtonContainer()
        setButtonContainerLayout()

        createRotationButton()
        createSetRatioButton()

        if mode == .normal {
            createResetButton(with: ToolBarButtonImageBuilder.resetImage())
            createCancelButton()
            createCropButton()
            addButtonsToContainer(buttons: [cancelButton, anticlockRotateButton, resetButton, setRatioButton, cropButton])
        } else {
            createResetButton()
            addButtonsToContainer(buttons: [anticlockRotateButton, resetButton, setRatioButton])
        }
    }
    
    func checkOrientation() {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            optionButtonStackView?.axis = .horizontal
            optionButtonStackView?.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        } else {
            optionButtonStackView?.axis = .vertical
            optionButtonStackView?.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        }
    }
    
    @objc private func cancel() {
        selectedCancel()
    }
    
    @objc private func setRatio() {
        selectedSetRatio()
    }
    
    @objc private func reset(_ sender: Any) {
        selectedReset()
    }
    
    @objc private func rotate(_ sender: Any) {
        selectedRotate()
    }
    
    @objc private func crop(_ sender: Any) {
        selectedCrop()
    }
}
