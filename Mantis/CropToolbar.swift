//
//  CropToolbar.swift
//  Mantis
//
//  Created by Echo on 11/6/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

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
        let buttonRect = CGRect.zero
        let buttonColor = UIColor.white
        let buttonFont = UIFont.systemFont(ofSize: 20)
        
        let button = UIButton(frame: buttonRect)
        button.titleLabel?.font = buttonFont
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        
        if let title = title {
            button.setTitle(title, for: .normal)
            button.setTitleColor(buttonColor, for: .normal)
        }
        
        button.addTarget(self, action: action, for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        
        return button
    }
    
    private func createCancelButton() {
        cancelButton = createOptionButton(withTitle: "Cancel", andAction: #selector(cancel))
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
            resetButton = createOptionButton(withTitle: "Reset", andAction: #selector(reset))
        }
    }
    
    private func createSetRatioButton() {
        setRatioButton = createOptionButton(withTitle: nil, andAction: #selector(setRatio))
        setRatioButton?.setImage(ToolBarButtonImageBuilder.clampImage(), for: .normal)
    }
    
    private func createCropButton() {
        cropButton = createOptionButton(withTitle: "Done", andAction: #selector(crop))
    }
    
    private func createButtonContainer() {
        optionButtonStackView = UIStackView()
        addSubview(optionButtonStackView!)
        
        optionButtonStackView?.translatesAutoresizingMaskIntoConstraints = false
        optionButtonStackView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionButtonStackView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        optionButtonStackView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        optionButtonStackView?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        optionButtonStackView?.distribution = .equalCentering
    }
    
    private func addButtonsToContainer(buttons: [UIButton]) {
        buttons.forEach{
            optionButtonStackView?.addArrangedSubview($0)
        }
    }
    
    func createToolbarUI() {
        createCancelButton()
        createRotationButton()
        createResetButton(with: ToolBarButtonImageBuilder.resetImage())
        createSetRatioButton()
        createCropButton()
        
        createButtonContainer()
        addButtonsToContainer(buttons: [cancelButton!, anticlockRotateButton!, resetButton!, setRatioButton!, cropButton!])
    }
    
    func createBottomOpertions() {
        createRotationButton()
        createResetButton()
        createSetRatioButton()
        
        createButtonContainer()
        addButtonsToContainer(buttons: [anticlockRotateButton!, resetButton!, setRatioButton!])
    }
    
    func checkOrientation() {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            optionButtonStackView?.axis = .horizontal
        } else {
            optionButtonStackView?.axis = .vertical
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
