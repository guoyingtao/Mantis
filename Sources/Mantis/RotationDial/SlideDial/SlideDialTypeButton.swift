//
//  SlideDialTypeButton.swift
//  Mantis
//
//  A circular button used in the Apple Photos–style rotation type selector.
//  Shows an icon when at zero, or a numeric value when adjusted.
//  The ring around the button indicates whether the value is non-zero.
//

import UIKit

// MARK: - SlideDialTypeButton

/// A circular button that represents one of the three adjustment types
/// (Straighten, Vertical Skew, Horizontal Skew).
///
/// **Appearance states:**
/// - Unselected, value == 0: gray ring, dark icon
/// - Selected, value == 0: gray ring, dark icon (larger, centered above ruler)
/// - Selected, value != 0: golden ring with progress arc, golden value text
/// - Unselected, value != 0: gray ring with a small dot indicating non-zero
final class SlideDialTypeButton: UIView {
    
    let adjustmentType: RotationAdjustmentType
    
    private(set) var isSelectedType = false
    private(set) var currentValue: CGFloat = 0
    private var limitation: CGFloat = 45
    
    private let iconView = UIImageView()
    private let valueLabel = UILabel()
    private let ringLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    private var config: SlideDialConfig
    
    init(type: RotationAdjustmentType, config: SlideDialConfig) {
        self.adjustmentType = type
        self.config = config
        self.limitation = config.limitation(for: type)
        super.init(frame: .zero)
        setupLayers()
        setupSubviews()
        updateAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *),
           traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            ringLayer.fillColor = config.buttonFillColor.cgColor
            updateAppearance()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let ringRect = bounds.insetBy(dx: 2, dy: 2)
        let ringPath = UIBezierPath(ovalIn: ringRect)
        ringLayer.path = ringPath.cgPath
        ringLayer.frame = bounds
        
        progressLayer.path = ringPath.cgPath
        progressLayer.frame = bounds
        
        iconView.frame = bounds.insetBy(dx: bounds.width * 0.28, dy: bounds.height * 0.28)
        valueLabel.frame = bounds
    }
    
    private func setupLayers() {
        // Background ring with dark fill
        ringLayer.fillColor = config.buttonFillColor.cgColor
        ringLayer.strokeColor = config.ringColor.cgColor
        ringLayer.lineWidth = 2.5
        layer.addSublayer(ringLayer)
        
        // Progress arc (only visible when value != 0 and selected)
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = config.activeColor.cgColor
        progressLayer.lineWidth = 2.5
        progressLayer.lineCap = .round
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }
    
    private func setupSubviews() {
        let iconSize = CGSize(width: 24, height: 24)
        let icon = SlideDialIconDrawer.iconImage(for: adjustmentType,
                                                  size: iconSize,
                                                  color: config.iconColor,
                                                  backgroundColor: config.buttonFillColor)
        iconView.image = icon
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)
        
        valueLabel.textAlignment = .center
        valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        valueLabel.isHidden = true
        addSubview(valueLabel)
    }
    
    // MARK: - Public API
    
    func setSelected(_ selected: Bool) {
        isSelectedType = selected
        updateAppearance()
    }
    
    func setValue(_ value: CGFloat) {
        currentValue = value
        updateAppearance()
    }
    
    func setLimitation(_ limit: CGFloat) {
        self.limitation = limit
    }
    
    // MARK: - Appearance
    
    private func updateAppearance() {
        let hasValue = abs(currentValue) > 0.5
        
        if isSelectedType && hasValue {
            // Selected + has value: show golden ring arc + value text
            iconView.isHidden = true
            valueLabel.isHidden = false
            valueLabel.text = "\(Int(round(currentValue)))"
            valueLabel.textColor = currentValue > 0 ? config.activeColor : config.inactiveColor
            
            ringLayer.strokeColor = config.ringColor.cgColor
            progressLayer.strokeColor = currentValue > 0 ? config.activeColor.cgColor : config.inactiveColor.cgColor
            progressLayer.isHidden = false
            
            // Calculate progress: map value to 0...1 stroke range
            let progress = min(abs(currentValue) / limitation, 1.0)
            // Start from top (12 o'clock); clockwise for positive, counter-clockwise for negative
            if currentValue > 0 {
                progressLayer.strokeStart = 0
                progressLayer.strokeEnd = progress
            } else {
                progressLayer.strokeStart = 1.0 - progress
                progressLayer.strokeEnd = 1.0
            }
            
            // Rotate so stroke starts from 12 o'clock
            progressLayer.transform = CATransform3DMakeRotation(-.pi / 2, 0, 0, 1)
            
        } else if isSelectedType {
            // Selected + zero value: show icon, gray ring
            iconView.isHidden = false
            valueLabel.isHidden = true
            progressLayer.isHidden = true
            ringLayer.strokeColor = config.ringColor.cgColor
            refreshIcon(color: config.iconColor)
            
        } else {
            // Not selected: show icon, gray ring
            iconView.isHidden = false
            valueLabel.isHidden = true
            progressLayer.isHidden = true
            ringLayer.strokeColor = config.ringColor.cgColor
            refreshIcon(color: config.iconColor)
        }
    }
    
    private func refreshIcon(color: UIColor) {
        let iconSize = CGSize(width: 24, height: 24)
        iconView.image = SlideDialIconDrawer.iconImage(for: adjustmentType,
                                                        size: iconSize,
                                                        color: color,
                                                        backgroundColor: config.buttonFillColor)
    }
}
