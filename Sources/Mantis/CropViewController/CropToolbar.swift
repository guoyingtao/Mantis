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

public class CropToolbar: UIView, CropToolbarProtocol {
    public var heightForVerticalOrientationConstraint: NSLayoutConstraint?
    public var widthForHorizonOrientationConstraint: NSLayoutConstraint?
    
    public var cropToolbarDelegate: CropToolbarDelegate?
    
    var fixedRatioSettingButton: UIButton?

    var cancelButton: UIButton?
    var resetButton: UIButton?
    var counterClockwiseRotationButton: UIButton?
    var clockwiseRotationButton: UIButton?
    var cropButton: UIButton?
    
    var config: CropToolbarConfig!
    
    private var optionButtonStackView: UIStackView?
    
    private func createOptionButton(withTitle title: String?, andAction action: Selector) -> UIButton {
        let buttonColor = UIColor.white
        let buttonFontSize: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ?
            config.optionButtonFontSizeForPad :
            config.optionButtonFontSize
        
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
    
    private func createCounterClockwiseRotationButton() {
        counterClockwiseRotationButton = createOptionButton(withTitle: nil, andAction: #selector(counterClockwiseRotate))
        counterClockwiseRotationButton?.setImage(ToolBarButtonImageBuilder.rotateCCWImage(), for: .normal)
    }

    private func createClockwiseRotationButton() {
        clockwiseRotationButton = createOptionButton(withTitle: nil, andAction: #selector(clockwiseRotate))
        clockwiseRotationButton?.setImage(ToolBarButtonImageBuilder.rotateCWImage(), for: .normal)
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
        fixedRatioSettingButton = createOptionButton(withTitle: nil, andAction: #selector(setRatio))
        fixedRatioSettingButton?.setImage(ToolBarButtonImageBuilder.clampImage(), for: .normal)
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
    
    private func addButtonsToContainer(button: UIButton?) {
        if let button = button {
            optionButtonStackView?.addArrangedSubview(button)
        }
    }
    
    private func addButtonsToContainer(buttons: [UIButton?]) {
        buttons.forEach{
            if let button = $0 {
                optionButtonStackView?.addArrangedSubview(button)
            }
        }
    }
    
    public func createToolbarUI(config: CropToolbarConfig) {
        self.config = config
        backgroundColor = .black
        
        createButtonContainer()
        setButtonContainerLayout()
        
        if config.mode == .normal {
            createCancelButton()
            addButtonsToContainer(button: cancelButton)
        }
        
        if config.toolbarButtonOptions.contains(.counterclockwiseRotate) {
            createCounterClockwiseRotationButton()
            addButtonsToContainer(button: counterClockwiseRotationButton)
        }
        
        if config.toolbarButtonOptions.contains(.clockwiseRotate) {
            createClockwiseRotationButton()
            addButtonsToContainer(button: clockwiseRotationButton)
        }
        
        if config.toolbarButtonOptions.contains(.reset) {
            createResetButton(with: ToolBarButtonImageBuilder.resetImage())
            addButtonsToContainer(button: resetButton)
            resetButton?.isHidden = true
        }
        
        if config.toolbarButtonOptions.contains(.ratio) {
            if config.includeFixedRatioSettingButton  {
                createSetRatioButton()
                addButtonsToContainer(button: fixedRatioSettingButton)
            }
        }
        
        if config.mode == .normal {
            createCropButton()
            addButtonsToContainer(button: cropButton)
        }
    }
    
    public func getRatioListPresentSourceView() -> UIView? {
        return fixedRatioSettingButton
    }
        
    public func respondToOrientationChange() {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            optionButtonStackView?.axis = .horizontal
            optionButtonStackView?.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        } else {
            optionButtonStackView?.axis = .vertical
            optionButtonStackView?.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        }
    }
    
    public func handleFixedRatioSetted() {
        fixedRatioSettingButton?.tintColor = nil
    }
    
    public func handleFixedRatioUnSetted() {
        fixedRatioSettingButton?.tintColor = .white
    }
    
    public func handleCropViewDidBecomeResettable() {
        resetButton?.isHidden = false
    }
    
    public func handleCropViewDidBecomeUnResettable() {
        resetButton?.isHidden = true
    }
    
    public func initConstraints(heightForVerticalOrientation: CGFloat, widthForHorizonOrientation: CGFloat) {
        
    }
    
    @objc private func cancel() {
        cropToolbarDelegate?.didSelectCancel()
    }
    
    @objc private func setRatio() {
        cropToolbarDelegate?.didSelectSetRatio()
    }
    
    @objc private func reset(_ sender: Any) {
        cropToolbarDelegate?.didSelectReset()
    }
    
    @objc private func counterClockwiseRotate(_ sender: Any) {
        cropToolbarDelegate?.didSelectCounterClockwiseRotate()
    }
    
    @objc private func clockwiseRotate(_ sender: Any) {
        cropToolbarDelegate?.didSelectClockwiseRotate()
    }
    
    @objc private func crop(_ sender: Any) {
        cropToolbarDelegate?.didSelectCrop()
    }
}
