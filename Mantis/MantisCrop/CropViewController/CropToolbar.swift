//
//  CropToolbar.swift
//  Mantis
//
//  Created by Echo on 11/6/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropToolbar: UIView {
    
    let recommendHeight = 44
    let recommendWidth = 80
    let recommendHeightForCustom = 88
    let recommendWidthForCustom = 124
    
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
    private var customButtonStackView: UIStackView?
    private var wholeButtonStackView: UIStackView?
    
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
        
        optionButtonStackView?.distribution = .equalCentering
    }
    
    private func setButtonContainerLayout() {
        optionButtonStackView?.translatesAutoresizingMaskIntoConstraints = false
        optionButtonStackView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionButtonStackView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        optionButtonStackView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        optionButtonStackView?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    private func createCustomButtonContainer() {
        customButtonStackView = UIStackView()
        addSubview(customButtonStackView!)
        customButtonStackView?.distribution = .equalSpacing
    }
    
    private func setLayoutForCustomButtonContainer() {
        wholeButtonStackView?.translatesAutoresizingMaskIntoConstraints = false
        wholeButtonStackView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        wholeButtonStackView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        wholeButtonStackView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        wholeButtonStackView?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    private func createWholeButtonContainer() {
        createButtonContainer()
        createCustomButtonContainer()
        
        wholeButtonStackView = UIStackView()
        wholeButtonStackView?.distribution = .fillProportionally
        addSubview(wholeButtonStackView!)
        wholeButtonStackView?.addArrangedSubview(optionButtonStackView!)
        wholeButtonStackView?.addArrangedSubview(customButtonStackView!)
    }
    
    private func addButtonsToContainer(buttons: [UIButton]) {
        buttons.forEach{
            optionButtonStackView?.addArrangedSubview($0)
        }
    }
    
    private func addButtonToCustomContainer() {
        customButtonStackView?.addArrangedSubview(cancelButton!)
        customButtonStackView?.addArrangedSubview(cropButton!)
    }
    
    func createDefaultButtons(setResetImage: Bool = true) {
        createCancelButton()
        createRotationButton()
        
        if setResetImage {
            createResetButton(with: ToolBarButtonImageBuilder.resetImage())
        } else {
            createResetButton()
        }
        
        createSetRatioButton()
        createCropButton()
    }
    
    func createToolbarUI() {
        createDefaultButtons()
        createButtonContainer()
        setButtonContainerLayout()
        addButtonsToContainer(buttons: [cancelButton!, anticlockRotateButton!, resetButton!, setRatioButton!, cropButton!])
    }
    
    func createBottomOpertions() {
        createDefaultButtons(setResetImage: false)        
        createWholeButtonContainer()
        setLayoutForCustomButtonContainer()
        addButtonsToContainer(buttons: [anticlockRotateButton!, resetButton!, setRatioButton!])
        addButtonToCustomContainer()
    }
    
    func checkOrientation() {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            optionButtonStackView?.axis = .horizontal
            customButtonStackView?.axis = .horizontal
            wholeButtonStackView?.axis = .vertical
        } else {
            optionButtonStackView?.axis = .vertical
            customButtonStackView?.axis = .vertical
            wholeButtonStackView?.axis = .horizontal
            
            if UIApplication.shared.statusBarOrientation == .landscapeLeft {
                wholeButtonStackView?.removeArrangedSubview(customButtonStackView!)
                wholeButtonStackView?.addArrangedSubview(customButtonStackView!)
            } else {
                wholeButtonStackView?.removeArrangedSubview(optionButtonStackView!)
                wholeButtonStackView?.addArrangedSubview(optionButtonStackView!)
            }
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

extension CropToolbar {
    func add(button: UIButton) {
        customButtonStackView?.insertArrangedSubview(button, at: 1)
    }
}
