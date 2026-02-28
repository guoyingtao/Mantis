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
    var appearanceMode: AppearanceMode = .forceDark
    
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
    
    // MARK: - Liquid Glass (iOS 26+)
    private var glassStackView: UIStackView?
    private var toolGroupContainerView: UIVisualEffectView?
    private var glassWrapperMap: [ObjectIdentifier: UIVisualEffectView] = [:]
    private var toolGroupHeightConstraint: NSLayoutConstraint?
    private var toolGroupWidthConstraint: NSLayoutConstraint?
    
    private var autoAdjustButtonActive = false {
        didSet {
            if autoAdjustButtonActive {
                autoAdjustButton.tintColor = .yellow
            } else {
                autoAdjustButton.tintColor = AppearanceColorPreset.autoAdjustInactiveColor(for: appearanceMode)
            }
        }
    }
    
    public func createToolbarUI(config: CropToolbarConfig) {
        self.config = config
                
        backgroundColor = config.backgroundColor
                
        if #available(macCatalyst 14.0, iOS 14.0, *) {
            if UIDevice.current.userInterfaceIdiom == .mac {
                backgroundColor = AppearanceColorPreset.toolbarBackground(for: appearanceMode)
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
        
        if #available(iOS 26.0, *) {
            applyLiquidGlassEffect()
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        
        let glassExtraPadding: CGFloat
        if #available(iOS 26.0, *) {
            glassExtraPadding = 16
        } else {
            glassExtraPadding = 0
        }

        if Orientation.treatAsPortrait {
            return CGSize(width: superSize.width, height: config.heightForVerticalOrientation + glassExtraPadding)
        } else {
            return CGSize(width: config.widthForHorizontalOrientation + glassExtraPadding, height: superSize.height)
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
        
        if #available(iOS 26.0, *) {
            adjustGlassLayoutForOrientation()
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
        glassWrapper(for: resetButton)?.isHidden = false
    }

    public func handleCropViewDidBecomeUnResettable() {
        resetButton?.isHidden = true
        glassWrapper(for: resetButton)?.isHidden = true
    }
    
    public func handleImageAutoAdjustable() {
        autoAdjustButton.isHidden = false
        glassWrapper(for: autoAdjustButton)?.isHidden = false
    }
    
    public func handleImageNotAutoAdjustable() {
        autoAdjustButton.isHidden = true
        glassWrapper(for: autoAdjustButton)?.isHidden = true
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
    
    private func glassWrapper(for button: UIButton?) -> UIVisualEffectView? {
        guard let button = button else { return nil }
        return glassWrapperMap[ObjectIdentifier(button)]
    }
}

// MARK: - Liquid Glass (iOS 26+)
@available(iOS 26.0, *)
extension CropToolbar {
    /// Wraps a single button in its own glass capsule
    private func wrapButtonInGlass(_ button: UIButton) -> UIVisualEffectView {
        let glassEffect = UIGlassEffect()
        glassEffect.isInteractive = true
        let wrapper = UIVisualEffectView(effect: glassEffect)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.cornerConfiguration = .capsule()
        
        button.removeFromSuperview()
        button.translatesAutoresizingMaskIntoConstraints = false
        wrapper.contentView.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: wrapper.contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: wrapper.contentView.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: wrapper.contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: wrapper.contentView.trailingAnchor)
        ])
        
        glassWrapperMap[ObjectIdentifier(button)] = wrapper
        return wrapper
    }
    
    /// Wraps a single button in a circular glass background
    private func wrapButtonInCircularGlass(_ button: UIButton, size: CGFloat = 44) -> UIVisualEffectView {
        let glassEffect = UIGlassEffect()
        glassEffect.isInteractive = true
        let wrapper = UIVisualEffectView(effect: glassEffect)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.cornerConfiguration = .capsule()
        
        button.removeFromSuperview()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = .zero
        wrapper.contentView.addSubview(button)
        
        NSLayoutConstraint.activate([
            wrapper.widthAnchor.constraint(equalToConstant: size),
            wrapper.heightAnchor.constraint(equalToConstant: size),
            button.centerXAnchor.constraint(equalTo: wrapper.contentView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: wrapper.contentView.centerYAnchor),
            button.widthAnchor.constraint(equalTo: wrapper.contentView.widthAnchor),
            button.heightAnchor.constraint(equalTo: wrapper.contentView.heightAnchor)
        ])
        
        glassWrapperMap[ObjectIdentifier(button)] = wrapper
        return wrapper
    }
    
    /// Wraps multiple buttons in a single shared glass capsule
    private func wrapButtonsInGlass(_ buttons: [UIButton], size: CGFloat = 44) -> UIVisualEffectView {
        let glassEffect = UIGlassEffect()
        let wrapper = UIVisualEffectView(effect: glassEffect)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.cornerConfiguration = .capsule()
        
        let isPortrait = Orientation.treatAsPortrait
        
        let stack = UIStackView()
        stack.axis = isPortrait ? .horizontal : .vertical
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        wrapper.contentView.addSubview(stack)
        
        let heightConstraint = wrapper.heightAnchor.constraint(equalToConstant: size)
        let widthConstraint = wrapper.widthAnchor.constraint(equalToConstant: size)
        
        heightConstraint.isActive = isPortrait
        widthConstraint.isActive = !isPortrait
        
        toolGroupHeightConstraint = heightConstraint
        toolGroupWidthConstraint = widthConstraint
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: wrapper.contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: wrapper.contentView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: wrapper.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: wrapper.contentView.trailingAnchor)
        ])
        
        for button in buttons {
            button.removeFromSuperview()
            button.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(button)
        }
        
        return wrapper
    }
    
    func applyLiquidGlassEffect() {
        guard let stackView = optionButtonStackView else { return }
        
        backgroundColor = .clear
        
        // Main layout stack
        let mainStack = UIStackView()
        mainStack.axis = Orientation.treatAsPortrait ? .horizontal : .vertical
        mainStack.distribution = .equalCentering
        mainStack.alignment = .center
        mainStack.isLayoutMarginsRelativeArrangement = true
        mainStack.layoutMargins = Orientation.treatAsPortrait
            ? UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            : UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        glassStackView = mainStack
        
        // Collect buttons from original stack view
        let arrangedViews = stackView.arrangedSubviews
        var cancelBtn: UIButton?
        var cropBtn: UIButton?
        var toolButtons: [UIButton] = []
        
        for view in arrangedViews {
            guard let button = view as? UIButton else { continue }
            if button === cancelButton {
                cancelBtn = button
            } else if button === cropButton {
                cropBtn = button
            } else {
                toolButtons.append(button)
            }
        }
        
        // Remove all from original stack
        for view in arrangedViews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        // Add Cancel button (circular glass with xmark icon)
        if let cancel = cancelBtn {
            cancel.setTitle(nil, for: .normal)
            let xmarkConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
            let xmarkImage = UIImage(systemName: "xmark", withConfiguration: xmarkConfig)
            cancel.setImage(xmarkImage, for: .normal)
            cancel.tintColor = .label
            let wrapped = wrapButtonInCircularGlass(cancel)
            mainStack.addArrangedSubview(wrapped)
        }
        
        // Add tool buttons into one shared glass capsule
        if !toolButtons.isEmpty {
            for button in toolButtons {
                button.tintColor = .label
                button.setTitleColor(.label, for: .normal)
            }
            let toolGlass = wrapButtonsInGlass(toolButtons)
            toolGroupContainerView = toolGlass
            mainStack.addArrangedSubview(toolGlass)
        }
        
        // Add Done/Crop button (circular glass with checkmark icon)
        if let crop = cropBtn {
            crop.setTitle(nil, for: .normal)
            let checkmarkConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
            let checkmarkImage = UIImage(systemName: "checkmark", withConfiguration: checkmarkConfig)
            crop.setImage(checkmarkImage, for: .normal)
            crop.tintColor = .label
            let wrapped = wrapButtonInCircularGlass(crop)
            mainStack.addArrangedSubview(wrapped)
        }
        
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // Hide original stack view
        stackView.isHidden = true
    }
    
    func adjustGlassLayoutForOrientation() {
        let isPortrait = Orientation.treatAsPortrait
        let axis: NSLayoutConstraint.Axis = isPortrait ? .horizontal : .vertical
        let margins = isPortrait
            ? UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            : UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        
        glassStackView?.axis = axis
        glassStackView?.layoutMargins = margins
        
        // Swap dimension constraints for the tool group capsule
        toolGroupHeightConstraint?.isActive = isPortrait
        toolGroupWidthConstraint?.isActive = !isPortrait
        
        // Update tool group stack axis
        if let toolGroup = toolGroupContainerView,
           let toolStack = toolGroup.contentView.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            toolStack.axis = axis
        }
    }
}
