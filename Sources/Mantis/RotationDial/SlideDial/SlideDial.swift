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
    
    var hideInactiveButtonsTimer: Timer?
    var inactiveButtonsHidden = false
    
    // MARK: - Type selector mode properties
    
    var typeButtons: [RotationAdjustmentType: SlideDialTypeButton] = [:]
    
    /// The current limitation based on the active adjustment type
    var currentLimitation: CGFloat {
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
    
    // MARK: - Indicator
    
    private func setIndicator(with angle: Angle) {
        switch config.mode {
        case .simple:
            indicator?.text = "\(Int(round(angle.degrees)))"
            indicator?.textColor = angle.degrees > 0 ? config.activeColor : config.inactiveColor
        case .withTypeSelector:
            updateSelectedTypeButton(with: angle.degrees)
        }
    }
    
    func handleRotation(by angle: Angle) {
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
        switch config.mode {
        case .simple:
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
        case .withTypeSelector:
            layoutTypeButtons(animated: false)
            
            let buttonTransform: CGAffineTransform
            if Orientation.treatAsPortrait {
                buttonTransform = .identity
            } else if Orientation.isLandscapeRight {
                buttonTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            } else {
                buttonTransform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            }
            
            for (_, button) in typeButtons {
                button.transform = buttonTransform
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
