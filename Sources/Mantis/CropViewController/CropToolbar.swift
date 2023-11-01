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

public final class CropToolbar: UIView, CropToolbarProtocol {
    public var config = CropToolbarConfig()
    public var iconProvider: CropToolbarIconProvider?
    
    public weak var delegate: CropToolbarDelegate?
        
    private lazy var counterClockwiseRotationButton: UIButton = {
        let button = createOptionButton(withTitle: nil, andAction: #selector(counterClockwiseRotate))
        let icon = iconProvider?.getCounterClockwiseRotationIcon() ?? ToolBarButtonImageBuilder.rotateCCWImage()
        button.setImage(icon, for: .normal)
        button.accessibilityIdentifier = "CounterClockwiseRotationButton"
        button.accessibilityLabel = LocalizedHelper.getString("Mantis.CounterClockwise rotation", value: "CounterClockwise rotation")
        return button
    }()

    private lazy var clockwiseRotationButton: UIButton = {
        let button = createOptionButton(withTitle: nil, andAction: #selector(clockwiseRotate))
        let icon = iconProvider?.getClockwiseRotationIcon() ?? ToolBarButtonImageBuilder.rotateCWImage()
        button.setImage(icon, for: .normal)
        button.accessibilityIdentifier = "ClockwiseRotationButton"
        button.accessibilityLabel = LocalizedHelper.getString("Mantis.Clockwise rotation", value: "Clockwise rotation")
        return button
    }()

    private lazy var alterCropper90DegreeButton: UIButton = {
        let button = createOptionButton(withTitle: nil, andAction: #selector(alterCropper90Degree))
        let icon = iconProvider?.getAlterCropper90DegreeIcon() ?? ToolBarButtonImageBuilder.alterCropper90DegreeImage()
        button.setImage(icon, for: .normal)
        button.accessibilityIdentifier = "AlterCropper90DegreeButton"
        button.accessibilityLabel = LocalizedHelper.getString("Mantis.Alter cropper by 90 degrees", value: "Alter cropper by 90 degrees")
        return button
    }()
    
    private lazy var horizontallyFlipButton: UIButton = {
        let button = createOptionButton(withTitle: nil, andAction: #selector(horizontallyFlip))
        let icon = iconProvider?.getHorizontallyFlipIcon() ?? ToolBarButtonImageBuilder.horizontallyFlipImage()
        button.setImage(icon, for: .normal)
        button.accessibilityIdentifier = "HorizontallyFlipButton"
        button.accessibilityLabel = LocalizedHelper.getString("Mantis.Horizontally flip", value: "Horizontally flip")
        return button
    }()
    
    private lazy var verticallyFlipButton: UIButton = {
        let button = createOptionButton(withTitle: nil, andAction: #selector(verticallyFlip(_:)))
        let icon = iconProvider?.getVerticallyFlipIcon() ?? ToolBarButtonImageBuilder.verticallyFlipImage()
        button.setImage(icon, for: .normal)
        button.accessibilityIdentifier = "VerticallyFlipButton"
        button.accessibilityLabel = LocalizedHelper.getString("Mantis.Vertically flip", value: "Vertically flip")
        return button
    }()
    
    private lazy var autoAdjustButton: UIButton = {
        let button = createOptionButton(withTitle: nil, andAction: #selector(autoAdjust(_:)))
        let icon = iconProvider?.getAutoAdjustIcon() ?? ToolBarButtonImageBuilder.autoAdjustImage()
        button.setImage(icon, for: .normal)
        button.accessibilityIdentifier = "AutoAdjustButton"
        button.accessibilityLabel = LocalizedHelper.getString("Mantis.Auto adjust", value: "Auto adjust")
        return button
    }()

    private var fixedRatioSettingButton: UIButton?
    
    private lazy var cancelButton: UIButton = {
        if let icon = iconProvider?.getCancelIcon() {
            let button = createOptionButton(withTitle: nil, andAction: #selector(cancel))
            button.setImage(icon, for: .normal)
            return button
        }

        // Here we use Mantis.Cancel as a key in case of user want to use their own
        // localized string, use this key can avoid possible key conflict
        let cancelText = LocalizedHelper.getString("Mantis.Cancel", value: "Cancel")
        let button = createOptionButton(withTitle: cancelText, andAction: #selector(cancel))
        button.accessibilityIdentifier = "CancelButton"
        button.accessibilityLabel = cancelText
        return button
    }()

    private lazy var cropButton: UIButton = {
        if let icon = iconProvider?.getCropIcon() {
            let button = createOptionButton(withTitle: nil, andAction: #selector(crop))
            button.setImage(icon, for: .normal)
            return button
        }
        
        let doneText = LocalizedHelper.getString("Mantis.Done", value: "Done")
        let button = createOptionButton(withTitle: doneText, andAction: #selector(crop))
        button.accessibilityIdentifier = "DoneButton"
        button.accessibilityLabel = doneText
        return button
    }()

    private var resetButton: UIButton?
    private var optionButtonStackView: UIStackView?
    
    private var autoAdjustButtonActive = false {
        didSet {
            if autoAdjustButtonActive {
                autoAdjustButton.tintColor = .yellow
            } else {
                autoAdjustButton.tintColor = .gray
            }
        }
    }
    
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
        
        if config.toolbarButtonOptions.contains(.autoAdjust) {
            addButtonsToContainer(button: autoAdjustButton)
            autoAdjustButton.isHidden = true
            autoAdjustButtonActive = false
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

        if Orientation.treatAsPortrait {
            return CGSize(width: superSize.width, height: config.heightForVerticalOrientation)
        } else {
            return CGSize(width: config.widthForHorizontalOrientation, height: superSize.height)
        }
    }

    public func getRatioListPresentSourceView() -> UIView? {
        return fixedRatioSettingButton
    }

    public func adjustLayoutWhenOrientationChange() {
        if Orientation.treatAsPortrait {
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
    
    public func handleImageAutoAdjustable() {
        autoAdjustButton.isHidden = false
    }
    
    public func handleImageNotAutoAdjustable() {
        autoAdjustButton.isHidden = true
        autoAdjustButtonActive = false
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
    
    @objc private func autoAdjust(_ sender: Any) {
        autoAdjustButtonActive.toggle()
        delegate?.didSelectAutoAdjust(self, isActive: autoAdjustButtonActive)
    }

    @objc private func crop(_ sender: Any) {
        delegate?.didSelectCrop(self)
    }
}

// private functions
extension CropToolbar {
    private func createOptionButton(withTitle title: String?, andAction action: Selector) -> UIButton {
        let buttonColor = config.foregroundColor
        let buttonFont: UIFont = .preferredFont(forTextStyle: .body)
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        let maxSize = UIFont.systemFontSize * 1.5
        
        let button = UIButton(type: .system)
        button.tintColor = config.foregroundColor
        button.titleLabel?.font = fontMetrics.scaledFont(for: buttonFont, maximumPointSize: maxSize)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.minimumScaleFactor = 0.5
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let compressionPriority: Float
        
        if let title = title {
            button.setTitle(title, for: .normal)
            button.setTitleColor(buttonColor, for: .normal)
            button.accessibilityIdentifier = "\(title)"
            
            // Set content compression resistance priority
            compressionPriority = AutoLayoutPriorityType.high.rawValue + 2
        } else {
            // Set content compression resistance priority
            compressionPriority = AutoLayoutPriorityType.high.rawValue + 1
        }
        
        // Set content hugging priority
        let huggingPriority: Float = 250
        button.setContentHuggingPriority(UILayoutPriority(rawValue: huggingPriority), for: .horizontal)
        button.setContentHuggingPriority(UILayoutPriority(rawValue: huggingPriority), for: .vertical)

        // Set width constraint
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: button.intrinsicContentSize.width).isActive = true
        
        button.setContentCompressionResistancePriority(UILayoutPriority(rawValue: compressionPriority), for: .horizontal)
        button.setContentCompressionResistancePriority(UILayoutPriority(rawValue: compressionPriority), for: .vertical)

        button.addTarget(self, action: action, for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        
        button.isAccessibilityElement = true
        button.accessibilityTraits = .button

        return button
    }

    private func createResetButton(with image: UIImage? = nil) -> UIButton {
        let button: UIButton
        if let image = image {
            button = createOptionButton(withTitle: nil, andAction: #selector(reset))
            button.setImage(image, for: .normal)
        } else {
            let resetText = LocalizedHelper.getString("Mantis.Reset", value: "Reset")
            button = createOptionButton(withTitle: resetText, andAction: #selector(reset))
        }
        
        button.accessibilityIdentifier = "ResetButton"
        button.accessibilityLabel = LocalizedHelper.getString("Mantis.Reset", value: "Reset")
        return button
    }
    
    private func createSetRatioButton() -> UIButton {
        let button = createOptionButton(withTitle: nil, andAction: #selector(setRatio))
        let icon = iconProvider?.getSetRatioIcon() ?? ToolBarButtonImageBuilder.clampImage()
        button.setImage(icon, for: .normal)
        button.accessibilityIdentifier = "RatioButton"
        button.accessibilityLabel = LocalizedHelper.getString("Mantis.Aspect ratio", value: "Aspect ratio")
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
