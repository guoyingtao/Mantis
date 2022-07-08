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
    public var heightForVerticalOrientation: CGFloat?
    public var widthForHorizonOrientation: CGFloat?
    
    public var iconProvider: CropToolbarIconProvider?
    
    public weak var cropToolbarDelegate: CropToolbarDelegate?

    var fixedRatioSettingButton: UIButton?

    var cancelButton: UIButton?
    var resetButton: UIButton?
    var counterClockwiseRotationButton: UIButton?
    var clockwiseRotationButton: UIButton?
    var alterCropper90DegreeButton: UIButton?
    var cropButton: UIButton?

    var config: CropToolbarConfig!

    private var optionButtonStackView: UIStackView?
    
    public func createToolbarUI(config: CropToolbarConfig) {
        self.config = config
        backgroundColor = .black
                
        if #available(macCatalyst 14.0, iOS 14.0, *) {
            if UIDevice.current.userInterfaceIdiom == .mac {
                backgroundColor = .white
            }
        }

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

        if config.toolbarButtonOptions.contains(.alterCropper90Degree) {
            createAlterCropper90DegreeButton()
            addButtonsToContainer(button: alterCropper90DegreeButton)
        }

        if config.toolbarButtonOptions.contains(.reset) {
            let icon = iconProvider?.getResetIcon() ?? ToolBarButtonImageBuilder.resetImage()
            createResetButton(with: icon)
            addButtonsToContainer(button: resetButton)
            resetButton?.isHidden = true
        }

        if config.toolbarButtonOptions.contains(.ratio) && config.ratioCandidatesShowType == .presentRatioList {
            if config.includeFixedRatioSettingButton {
                createSetRatioButton()
                addButtonsToContainer(button: fixedRatioSettingButton)

                if config.presetRatiosButtonSelected {
                    handleFixedRatioSetted(ratio: 0)
                    resetButton?.isHidden = false
                }
            }
        }

        if config.mode == .normal {
            createCropButton()
            addButtonsToContainer(button: cropButton)
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        if Orientation.isPortrait {
            return CGSize(width: superSize.width, height: heightForVerticalOrientation ?? 44)
        } else {
            return CGSize(width: widthForHorizonOrientation ?? 44, height: superSize.height)
        }
    }

    public func getRatioListPresentSourceView() -> UIView? {
        return fixedRatioSettingButton
    }

    public func adjustLayoutWhenOrientationChange() {
        if Orientation.isPortrait {
            optionButtonStackView?.axis = .horizontal
            optionButtonStackView?.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        } else {
            optionButtonStackView?.axis = .vertical
            optionButtonStackView?.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        }
    }

    public func handleFixedRatioSetted(ratio: Double) {
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
}

// Objc functions
extension CropToolbar {
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

    @objc private func alterCropper90Degree(_ sender: Any) {
        cropToolbarDelegate?.didSelectAlterCropper90Degree()
    }

    @objc private func crop(_ sender: Any) {
        cropToolbarDelegate?.didSelectCrop()
    }
}

// private functions
extension CropToolbar {
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
        let cancelText = LocalizedHelper.getString("Mantis.Cancel", value: "Cancel")
        cancelButton = createOptionButton(withTitle: cancelText, andAction: #selector(cancel))
    }

    private func createCounterClockwiseRotationButton() {
        counterClockwiseRotationButton = createOptionButton(withTitle: nil, andAction: #selector(counterClockwiseRotate))
        let icon = iconProvider?.getCounterClockwiseRotationIcon() ?? ToolBarButtonImageBuilder.rotateCCWImage()
        counterClockwiseRotationButton?.setImage(icon, for: .normal)
    }

    private func createClockwiseRotationButton() {
        clockwiseRotationButton = createOptionButton(withTitle: nil, andAction: #selector(clockwiseRotate))
        let icon = iconProvider?.getClockwiseRotationIcon() ?? ToolBarButtonImageBuilder.rotateCWImage()
        clockwiseRotationButton?.setImage(icon, for: .normal)
    }

    private func createAlterCropper90DegreeButton() {
        alterCropper90DegreeButton = createOptionButton(withTitle: nil, andAction: #selector(alterCropper90Degree))
        let icon = iconProvider?.getAlterCropper90DegreeIcon() ?? ToolBarButtonImageBuilder.alterCropper90DegreeImage()
        alterCropper90DegreeButton?.setImage(icon, for: .normal)
    }

    private func createResetButton(with image: UIImage? = nil) {
        if let image = image {
            resetButton = createOptionButton(withTitle: nil, andAction: #selector(reset))
            resetButton?.setImage(image, for: .normal)
        } else {
            let resetText = LocalizedHelper.getString("Mantis.Reset", value: "Reset")
            resetButton = createOptionButton(withTitle: resetText, andAction: #selector(reset))
        }
    }

    private func createSetRatioButton() {
        fixedRatioSettingButton = createOptionButton(withTitle: nil, andAction: #selector(setRatio))
        let icon = iconProvider?.getSetRatioIcon() ?? ToolBarButtonImageBuilder.clampImage()
        fixedRatioSettingButton?.setImage(icon, for: .normal)
    }

    private func createCropButton() {
        let doneText = LocalizedHelper.getString("Mantis.Done", value: "Done")
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
        buttons.forEach {
            if let button = $0 {
                optionButtonStackView?.addArrangedSubview(button)
            }
        }
    }
}
