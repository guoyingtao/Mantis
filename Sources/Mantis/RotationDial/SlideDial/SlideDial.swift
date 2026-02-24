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

    private let hapticGenerator = UISelectionFeedbackGenerator()
    private var lastHapticStep: Int?
    
    private var hideInactiveButtonsTimer: Timer?
    private var inactiveButtonsHidden = false
    
    // MARK: - Type selector mode properties
    
    private var typeButtons: [RotationAdjustmentType: SlideDialTypeButton] = [:]
    
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

    private func handleScrollHaptics(for angle: Angle) {
        let currentStep = Int(angle.degrees.rounded(.towardZero))
        if lastHapticStep == nil {
            lastHapticStep = currentStep
            hapticGenerator.prepare()
            return
        }

        guard currentStep != lastHapticStep else {
            return
        }

        lastHapticStep = currentStep
        hapticGenerator.selectionChanged()
        hapticGenerator.prepare()
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
        lastHapticStep = nil
        showInactiveButtons()
        
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
        if case .withTypeSelector = config.mode {
            for (_, button) in typeButtons {
                if button.frame.contains(newPoint) {
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
    
    /// The fixed order of all adjustment types
    private let allTypes: [RotationAdjustmentType] = [.straighten, .verticalSkew, .horizontalSkew]
    
    private func createTypeButtons() {
        // Remove old buttons if re-laying out
        typeButtons.values.forEach { $0.removeFromSuperview() }
        typeButtons.removeAll()
        
        for type in allTypes {
            let button = SlideDialTypeButton(type: type, config: config)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(typeButtonTapped(_:)))
            button.addGestureRecognizer(tap)
            button.isUserInteractionEnabled = true
            
            addSubview(button)
            typeButtons[type] = button
        }
        
        // Set initial selection and layout
        typeButtons[.straighten]?.setSelected(true)
        layoutTypeButtons(animated: false)
    }
    
    /// Positions buttons in a fixed row, sliding the group horizontally so the
    /// selected button is centered above the ruler pointer (matching Apple Photos).
    private func layoutTypeButtons(animated: Bool) {
        let buttonSize = config.typeButtonSize
        let spacing = config.typeButtonSpacing
        let topPadding: CGFloat = 16
        let buttonY: CGFloat = topPadding
        let centerX = frame.width / 2
        
        // Index of the selected type in the fixed order
        let selectedIndex = allTypes.firstIndex(of: viewModel.currentAdjustmentType) ?? 0
                
        // Position of the selected button's center within the group (relative to group leading edge)
        let selectedCenterInGroup = CGFloat(selectedIndex) * (buttonSize + spacing) + buttonSize / 2
        
        // Offset so that the selected button's center aligns with the view's centerX
        let groupOriginX = centerX - selectedCenterInGroup
        
        let applyLayout = {
            for (idx, type) in self.allTypes.enumerated() {
                let originX = groupOriginX + CGFloat(idx) * (buttonSize + spacing)
                self.typeButtons[type]?.frame = CGRect(
                    x: originX,
                    y: buttonY,
                    width: buttonSize,
                    height: buttonSize
                )
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                applyLayout()
            }
        } else {
            applyLayout()
        }
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
        
        // Animate the selected button to center
        layoutTypeButtons(animated: true)
        
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
        layoutTypeButtons(animated: false)
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
    
    /// Called by CropView after a flip to sync the SlideDial's stored straighten value
    /// without disturbing the ruler when a skew tab is active.
    func syncStraightenValue(_ degrees: CGFloat) {
        guard case .withTypeSelector = config.mode else { return }
        
        viewModel.storeAngle(degrees, for: .straighten)
        typeButtons[.straighten]?.setValue(degrees)
        
        if viewModel.currentAdjustmentType == .straighten {
            let limit = config.limitation(for: .straighten)
            
            viewModel.didSetRotationAngle = { _ in }
            viewModel.rotationAngle = Angle(degrees: degrees)
            viewModel.didSetRotationAngle = { [weak self] angle in
                self?.handleRotation(by: angle)
            }
            
            slideRuler?.reset()
            if abs(degrees) > 0.5 {
                slideRuler?.setOffsetRatio(degrees / limit)
            }
        }
    }
    
    /// Called by CropView after a 90° rotation to sync the SlideDial's stored skew values
    /// with the swapped values in CropView's viewModel.
    func syncSkewValues(horizontal: CGFloat, vertical: CGFloat) {
        guard case .withTypeSelector = config.mode else { return }
        
        // Update stored angles
        viewModel.storeAngle(horizontal, for: .horizontalSkew)
        viewModel.storeAngle(vertical, for: .verticalSkew)
        
        // Update button displays
        typeButtons[.horizontalSkew]?.setValue(horizontal)
        typeButtons[.verticalSkew]?.setValue(vertical)
        
        // If the currently active type is a skew type, update ruler position
        let currentType = viewModel.currentAdjustmentType
        if currentType == .horizontalSkew || currentType == .verticalSkew {
            let newAngle = currentType == .horizontalSkew ? horizontal : vertical
            let limit = config.limitation(for: currentType)
            
            // Update viewModel angle without triggering external callback
            viewModel.didSetRotationAngle = { _ in }
            viewModel.rotationAngle = Angle(degrees: newAngle)
            viewModel.didSetRotationAngle = { [weak self] angle in
                self?.handleRotation(by: angle)
            }
            
            slideRuler?.reset()
            if abs(newAngle) > 0.5 {
                slideRuler?.setOffsetRatio(newAngle / limit)
            }
        }
    }
    
    // MARK: - Auto-hide inactive buttons during continuous operation
    
    private func startHideTimerIfNeeded() {
        guard case .withTypeSelector = config.mode else { return }
        guard hideInactiveButtonsTimer == nil else { return }
        
        let timer = Timer(timeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.hideInactiveButtons()
        }
        RunLoop.main.add(timer, forMode: .common)
        hideInactiveButtonsTimer = timer
    }
    
    private func hideInactiveButtons() {
        guard !inactiveButtonsHidden else { return }
        inactiveButtonsHidden = true
        let activeType = viewModel.currentAdjustmentType
        UIView.animate(withDuration: 0.25) {
            for (type, button) in self.typeButtons where type != activeType {
                button.alpha = 0
            }
        }
    }
    
    private func showInactiveButtons() {
        hideInactiveButtonsTimer?.invalidate()
        hideInactiveButtonsTimer = nil
        guard inactiveButtonsHidden else { return }
        inactiveButtonsHidden = false
        UIView.animate(withDuration: 0.25) {
            for (_, button) in self.typeButtons {
                button.alpha = 1
            }
        }
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
        showInactiveButtons()
        didFinishRotation()
    }
    
    func didGetOffsetRatio(from slideRuler: SlideRuler, offsetRatio: CGFloat) {
        let angle = Angle(degrees: currentLimitation * offsetRatio)
        handleScrollHaptics(for: angle)
        viewModel.rotationAngle = angle
        startHideTimerIfNeeded()
    }
}
