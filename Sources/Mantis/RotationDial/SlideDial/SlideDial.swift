//
//  SlideDial.swift
//  Mantis
//
//  Created by Yingtao Guo on 6/16/23.
//

import UIKit

final class SlideDial: UIView, RotationControlViewProtocol {
    var isAttachedToCropView = true
    
    var didUpdateRotationValue: (Angle) -> Void = { _ in }
    
    var didFinishRotation: () -> Void = {}
    
    /// Called when the user taps a different type button (only in withTypeSelector mode).
    /// The CropView should handle saving/restoring angles and applying the correct transform.
    var didSwitchAdjustmentType: ((RotationAdjustmentType) -> Void)?
    
    var indicator: UILabel!
    
    var slideRuler: SlideRuler!
    
    var viewModel = SlideDialViewModel()
    
    var config = SlideDialConfig()
    
    // MARK: - Type selector mode properties
    
    private var typeButtons: [RotationAdjustmentType: SlideDialTypeButton] = [:]
    private var typeButtonContainer: UIView?
    
    /// The current limitation based on the active adjustment type
    private var currentLimitation: CGFloat {
        config.limitation(for: viewModel.currentAdjustmentType)
    }
    
    init(frame: CGRect,
         config: SlideDialConfig,
         viewModel: SlideDialViewModel,
         slideRuler: SlideRuler) {
        super.init(frame: frame)
        self.config = config
        self.viewModel = viewModel
        self.slideRuler = slideRuler
        
        addSubview(slideRuler)
        
        self.viewModel.didSetRotationAngle = { [weak self] angle in
            self?.handleRotation(by: angle)
        }
        
        setAccessibilities()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Indicator (simple mode)
    
    private func setIndicator(with angle: Angle) {
        switch config.mode {
        case .simple:
            indicator?.text = "\(Int(round(angle.degrees)))"
            indicator?.textColor = angle.degrees > 0 ? config.activeColor : config.inactiveColor
        case .withTypeSelector:
            updateSelectedTypeButton(with: angle.degrees)
        }
    }
    
    private func handleRotation(by angle: Angle) {
        setIndicator(with: angle)
        didUpdateRotationValue(angle)
    }
    
    // MARK: - RotationControlViewProtocol
    
    @discardableResult
    func updateRotationValue(by angle: Angle) -> Bool {
        let limit = currentLimitation
        guard abs(angle.degrees) < limit else {
            return false
        }
        
        slideRuler?.setOffsetRatio(angle.degrees / limit)
        setIndicator(with: angle)

        return true
    }
    
    func reset() {
        transform = .identity
        
        switch config.mode {
        case .simple:
            viewModel.reset()
        case .withTypeSelector:
            viewModel.resetAll()
            resetAllTypeButtons()
        }
        
        if let slideRuler = slideRuler {
            slideRuler.reset()
        }
    }
    
    func getTouchTarget(with point: CGPoint) -> UIView {
        let newPoint = convert(point, to: self)
        
        // Check type buttons in withTypeSelector mode
        if case .withTypeSelector = config.mode,
           let container = typeButtonContainer {
            let containerPoint = convert(newPoint, to: container)
            for (_, button) in typeButtons {
                if button.frame.contains(containerPoint) {
                    return button
                }
            }
        }
        
        if let indicator = indicator, indicator.frame.contains(newPoint) {
            return indicator
        }
        
        return slideRuler.getTouchTarget()
    }
    
    func getLengthRatio() -> CGFloat {
        config.lengthRatio
    }
    
    func handleDeviceRotation() {
        if case .simple = config.mode {
            guard let indicator = indicator else {
                return
            }
            
            if Orientation.treatAsPortrait {
                indicator.transform = CGAffineTransform(rotationAngle: 0)
            } else if Orientation.isLandscapeRight {
                indicator.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            } else if Orientation.isLandscapeLeft {
                indicator.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            }
        }
    }
            
    func setupUI(withAllowableFrame allowableFrame: CGRect) {
        frame = allowableFrame
        
        switch config.mode {
        case .simple:
            createIndicator()
        case .withTypeSelector:
            createTypeButtons()
        }
        
        setupSlideRuler()
    }
    
    // MARK: - Simple mode indicator
    
    func createIndicator() {
        let indicatorSize = config.indicatorSize
        let indicatorFrame = CGRect(origin: CGPoint(x: (frame.width - indicatorSize.width) / 2, y: 0), size: indicatorSize)
        
        if let indicator = indicator {
            indicator.frame = indicatorFrame
        } else {
            indicator = UILabel(frame: indicatorFrame)
            indicator.textColor = config.inactiveColor
            indicator.textAlignment = .center
            addSubview(indicator)
            
            indicator.isUserInteractionEnabled = true
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleIndicatorTapped))
            indicator.addGestureRecognizer(tap)
        }
    }
    
    @objc func handleIndicatorTapped() {
        reset()
        didFinishRotation()
    }
    
    // MARK: - Type selector mode buttons
    
    private func createTypeButtons() {
        // Remove old container if re-laying out
        typeButtonContainer?.removeFromSuperview()
        typeButtons.removeAll()
        
        let container = UIView()
        container.backgroundColor = .clear
        addSubview(container)
        typeButtonContainer = container
        
        let buttonSize = config.typeButtonSize
        let spacing = config.typeButtonSpacing
        let types: [RotationAdjustmentType] = [.straighten, .verticalSkew, .horizontalSkew]
        let totalWidth = CGFloat(types.count) * buttonSize + CGFloat(types.count - 1) * spacing
        
        // Position container: centered horizontally, at top of SlideDial
        let containerHeight = buttonSize
        let containerY: CGFloat = (frame.height - config.slideRulerHeight - containerHeight) / 2
        container.frame = CGRect(
            x: (frame.width - totalWidth) / 2,
            y: max(0, containerY),
            width: totalWidth,
            height: containerHeight
        )
        
        for (index, type) in types.enumerated() {
            let button = SlideDialTypeButton(type: type, config: config)
            let originX = CGFloat(index) * (buttonSize + spacing)
            button.frame = CGRect(x: originX, y: 0, width: buttonSize, height: buttonSize)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(typeButtonTapped(_:)))
            button.addGestureRecognizer(tap)
            button.isUserInteractionEnabled = true
            
            container.addSubview(button)
            typeButtons[type] = button
        }
        
        // Set initial selection
        typeButtons[.straighten]?.setSelected(true)
    }
    
    @objc private func typeButtonTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedButton = gesture.view as? SlideDialTypeButton else { return }
        let newType = tappedButton.adjustmentType
        
        if newType == viewModel.currentAdjustmentType {
            // Tapping the already selected button resets that type's value
            viewModel.storeAngle(0, for: newType)
            viewModel.rotationAngle = Angle(degrees: 0)
            slideRuler?.reset()
            tappedButton.setValue(0)
            didFinishRotation()
            return
        }
        
        // Save current angle before switching
        viewModel.storeAngle(viewModel.rotationAngle.degrees, for: viewModel.currentAdjustmentType)
        
        // Update button selection states
        typeButtons[viewModel.currentAdjustmentType]?.setSelected(false)
        tappedButton.setSelected(true)
        
        // Switch type in viewModel
        viewModel.currentAdjustmentType = newType
        
        // Restore the stored angle for the new type
        let storedAngle = viewModel.storedAngle(for: newType)
        let newLimit = config.limitation(for: newType)
        
        // Reset ruler and set to new value
        slideRuler?.reset()
        if abs(storedAngle) > 0.5 {
            slideRuler?.setOffsetRatio(storedAngle / newLimit)
        }
        
        // Update viewModel without triggering external callback
        viewModel.didSetRotationAngle = { _ in }
        viewModel.rotationAngle = Angle(degrees: storedAngle)
        viewModel.didSetRotationAngle = { [weak self] angle in
            self?.handleRotation(by: angle)
        }
        
        // Notify CropView about type switch
        didSwitchAdjustmentType?(newType)
    }
    
    private func updateSelectedTypeButton(with degrees: CGFloat) {
        let currentType = viewModel.currentAdjustmentType
        typeButtons[currentType]?.setValue(degrees)
        viewModel.storeAngle(degrees, for: currentType)
    }
    
    private func resetAllTypeButtons() {
        for (_, button) in typeButtons {
            button.setValue(0)
            button.setSelected(false)
        }
        typeButtons[.straighten]?.setSelected(true)
    }
    
    /// Update type button values from external source (e.g. when CropView restores state)
    func updateTypeButtonValues(straighten: CGFloat, horizontal: CGFloat, vertical: CGFloat) {
        typeButtons[.straighten]?.setValue(straighten)
        typeButtons[.horizontalSkew]?.setValue(horizontal)
        typeButtons[.verticalSkew]?.setValue(vertical)
    }
    
    /// Get the currently selected adjustment type
    func getCurrentAdjustmentType() -> RotationAdjustmentType {
        viewModel.currentAdjustmentType
    }
    
    // MARK: - Slide ruler setup
    
    func setupSlideRuler() {
        let sliderFrame = CGRect(x: 0,
                                 y: frame.height - config.slideRulerHeight,
                                 width: frame.width,
                                 height: config.slideRulerHeight)
        slideRuler.frame = sliderFrame
        slideRuler.delegate = self
        slideRuler.forceAlignCenterFeedback = true
        slideRuler.setupUI()
    }
    
    // MARK: - Accessibility
    
    override func accessibilityIncrement() {
        viewModel.rotationAngle += Angle(degrees: 1)
        setAccessibilityValue()
    }
    
    override func accessibilityDecrement() {
        viewModel.rotationAngle -= Angle(degrees: -1)
        setAccessibilityValue()
    }
        
    func getTotalRotationValue() -> CGFloat {
        viewModel.rotationAngle.degrees
    }
}

// MARK: - SlideRulerDelegate

extension SlideDial: SlideRulerDelegate {
    func didFinishScroll() {
        didFinishRotation()
    }
    
    func didGetOffsetRatio(from slideRuler: SlideRuler, offsetRatio: CGFloat) {
        let angle = Angle(degrees: currentLimitation * offsetRatio)
        viewModel.rotationAngle = angle
    }
}
