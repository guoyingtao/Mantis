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
    case embedded // Without cancel and crop buttons
}

public class CropToolbar: UIView, CropToolbarProtocol {
    public var config = CropToolbarConfig()
    public var iconProvider: CropToolbarIconProvider?
    
    public weak var delegate: CropToolbarDelegate?
        
    private lazy var counterClockwiseRotationButton: UIButton = {
        let button = createOptionButton(withTitle: nil, andAction: #selector(counterClockwiseRotate))
        let icon = iconProvider?.getCounterClockwiseRotationIcon() ?? ToolBarButtonImageBuilder.rotateCCWImage()
        button.setImage(icon, for: .normal)
        return button
    }()

    private lazy var clockwiseRotationButton: UIButton = {
        let button = createOptionButton(withTitle: nil, andAction: #selector(clockwiseRotate))
        let icon = iconProvider?.getClockwiseRotationIcon() ?? ToolBarButtonImageBuilder.rotateCWImage()
        button.setImage(icon, for: .normal)
        return button
    }()

    private lazy var alterCropper90DegreeButton: UIButton = {
        let button = createOptionButton(withTitle: nil, andAction: #selector(alterCropper90Degree))
        let icon = iconProvider?.getAlterCropper90DegreeIcon() ?? ToolBarButtonImageBuilder.alterCropper90DegreeImage()
        button.setImage(icon, for: .normal)
        return button
    }()
    
    private lazy var horizontallyFlipButton: UIButton = {
        let button = createOptionButton(withTitle: nil, andAction: #selector(horizontallyFlip))
        let icon = iconProvider?.getHorizontallyFlipIcon() ?? ToolBarButtonImageBuilder.horizontallyFlipImage()
        button.setImage(icon, for: .normal)
        return button
    }()
    
    private lazy var verticallyFlipButton: UIButton = {
        let button = createOptionButton(withTitle: nil, andAction: #selector(verticallyFlip(_:)))
        let icon = iconProvider?.getVerticallyFlipIcon() ?? ToolBarButtonImageBuilder.verticallyFlipImage()
        button.setImage(icon, for: .normal)
        return button
    }()

    private var fixedRatioSettingButton: UIButton?
    
    private lazy var cancelButton: UIButton = {
        if let icon = iconProvider?.getCancelIcon() {
            let button = createOptionButton(withTitle: nil, andAction: #selector(cancel))
            button.setImage(icon, for: .normal)
            return button
        }

        let cancelText = LocalizedHelper.getString("Mantis.Cancel", value: "Cancel")
        return createOptionButton(withTitle: cancelText, andAction: #selector(cancel))
    }()

    private lazy var cropButton: UIButton = {
        if let icon = iconProvider?.getCropIcon() {
            let button = createOptionButton(withTitle: nil, andAction: #selector(crop))
            button.setImage(icon, for: .normal)
            return button
        }
        
        let doneText = LocalizedHelper.getString("Mantis.Done", value: "Done")
        return createOptionButton(withTitle: doneText, andAction: #selector(crop))
    }()

    private var resetButton: UIButton?
    private var optionButtonStackView: UIStackView?
    
    public func createToolbarUI(config: CropToolbarConfig) {
        self.config = config
                
        backgroundColor = config.backgroundColor
                
        if #available(macCatalyst 14.0, iOS 14.0, *) {
            if UIDevice.current.userInterfaceIdiom == .mac {
                backgroundColor = .white
            }
        }

        createButtonContainer()
        setButtonContainerLayout()

        if config.mode == .normal {
            addButtonsToContainer(button: cancelButton)
        }
        
        if config.toolbarButtonOptions.contains(.counterclockwiseRotate) {
            addButtonsToContainer(button: counterClockwiseRotationButton)
        }

        if config.toolbarButtonOptions.contains(.clockwiseRotate) {
            addButtonsToContainer(button: clockwiseRotationButton)
        }

        if config.toolbarButtonOptions.contains(.alterCropper90Degree) {
            addButtonsToContainer(button: alterCropper90DegreeButton)
        }
        
        if config.toolbarButtonOptions.contains(.horizontallyFlip) {
            addButtonsToContainer(button: horizontallyFlipButton)
        }
        
        if config.toolbarButtonOptions.contains(.verticallyFlip) {
            addButtonsToContainer(button: verticallyFlipButton)
        }

        if config.toolbarButtonOptions.contains(.reset) {
            let icon = iconProvider?.getResetIcon() ?? ToolBarButtonImageBuilder.resetImage()
            resetButton = createResetButton(with: icon)
            addButtonsToContainer(button: resetButton)
            resetButton?.isHidden = true
        }

        if config.toolbarButtonOptions.contains(.ratio) && config.ratioCandidatesShowType == .presentRatioListFromButton {
            if config.includeFixedRatiosSettingButton {
                fixedRatioSettingButton = createSetRatioButton()
                addButtonsToContainer(button: fixedRatioSettingButton!)

                if config.presetRatiosButtonSelected {
                    handleFixedRatioSetted(ratio: 0)
                    resetButton?.isHidden = false
                }
            }
        }

        if config.mode == .normal {
            addButtonsToContainer(button: cropButton)
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize

        if Orientation.isPortrait {
            return CGSize(width: superSize.width, height: config.heightForVerticalOrientation)
        } else {
            return CGSize(width: config.widthForHorizontalOrientation, height: superSize.height)
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
        fixedRatioSettingButton?.tintColor = config.foregroundColor
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
        delegate?.didSelectCancel(self)
    }

    @objc private func setRatio() {
        delegate?.didSelectSetRatio(self)
    }

    @objc private func reset(_ sender: Any) {
        delegate?.didSelectReset(self)
    }

    @objc private func counterClockwiseRotate(_ sender: Any) {
        delegate?.didSelectCounterClockwiseRotate(self)
    }

    @objc private func clockwiseRotate(_ sender: Any) {
        delegate?.didSelectClockwiseRotate(self)
    }

    @objc private func alterCropper90Degree(_ sender: Any) {
        delegate?.didSelectAlterCropper90Degree(self)
    }
    
    @objc private func horizontallyFlip(_ sender: Any) {
        delegate?.didSelectHorizontallyFlip(self)
    }

    @objc private func verticallyFlip(_ sender: Any) {
        delegate?.didSelectVerticallyFlip(self)
    }

    @objc private func crop(_ sender: Any) {
        delegate?.didSelectCrop(self)
    }
}

// private functions
extension CropToolbar {
    private func createOptionButton(withTitle title: String?, andAction action: Selector) -> UIButton {
        let buttonColor = config.foregroundColor
        let buttonFontSize: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ?
            config.optionButtonFontSizeForPad :
            config.optionButtonFontSize

        let buttonFont = UIFont.systemFont(ofSize: buttonFontSize)

        let button = UIButton(type: .system)
        button.tintColor = config.foregroundColor
        button.titleLabel?.font = buttonFont

        if let title = title {
            button.setTitle(title, for: .normal)
            button.setTitleColor(buttonColor, for: .normal)
        }

        button.addTarget(self, action: action, for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)

        return button
    }

    private func createResetButton(with image: UIImage? = nil) -> UIButton {
        if let image = image {
            let button = createOptionButton(withTitle: nil, andAction: #selector(reset))
            button.setImage(image, for: .normal)
            return button
        } else {
            let resetText = LocalizedHelper.getString("Mantis.Reset", value: "Reset")
            return createOptionButton(withTitle: resetText, andAction: #selector(reset))
        }
    }
    
    private func createSetRatioButton() -> UIButton {
        let button = createOptionButton(withTitle: nil, andAction: #selector(setRatio))
        let icon = iconProvider?.getSetRatioIcon() ?? ToolBarButtonImageBuilder.clampImage()
        button.setImage(icon, for: .normal)
        return button
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
