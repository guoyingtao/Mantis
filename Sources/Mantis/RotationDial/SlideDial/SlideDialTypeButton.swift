//
//  SlideDialTypeButton.swift
//  Mantis
//
//  A circular button used in the Apple Photos–style rotation type selector.
//  Shows an icon when at zero, or a numeric value when adjusted.
//  The ring around the button indicates whether the value is non-zero.
//

import UIKit

// MARK: - Icon Drawing

/// Draws icons that mimic the Apple Photos straighten/skew icons.
enum SlideDialIconDrawer {
    
    /// Draws the "Straighten" icon: a half-circle (horizon) with a horizontal line through it.
    static func drawStraightenIcon(in rect: CGRect, color: UIColor) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        let inset = rect.insetBy(dx: rect.width * 0.15, dy: rect.height * 0.15)
        let centerX = inset.midX
        let centerY = inset.midY + inset.height * 0.05
        let radius = inset.width * 0.38
        
        // Half circle (bottom half)
        let halfCircle = UIBezierPath()
        halfCircle.move(to: CGPoint(x: centerX - radius, y: centerY))
        halfCircle.addArc(withCenter: CGPoint(x: centerX, y: centerY),
                          radius: radius,
                          startAngle: .pi,
                          endAngle: 0,
                          clockwise: false)
        halfCircle.close()
        
        color.setFill()
        halfCircle.fill()
        
        // Horizontal line through center
        let lineY = centerY
        let lineLeft = centerX - radius * 1.4
        let lineRight = centerX + radius * 1.4
        
        let line = UIBezierPath()
        line.move(to: CGPoint(x: lineLeft, y: lineY))
        line.addLine(to: CGPoint(x: lineRight, y: lineY))
        line.lineWidth = 1.5
        color.setStroke()
        line.stroke()
        
        ctx.restoreGState()
    }
    
    /// Draws the "Vertical Skew" icon: a trapezoid shape narrowing at top with a vertical center line.
    static func drawVerticalSkewIcon(in rect: CGRect, color: UIColor) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        let inset = rect.insetBy(dx: rect.width * 0.2, dy: rect.height * 0.2)
        let centerX = inset.midX
        
        // Trapezoid: wider at bottom, narrower at top
        let topInset: CGFloat = inset.width * 0.15
        let path = UIBezierPath()
        path.move(to: CGPoint(x: inset.minX + topInset, y: inset.minY))
        path.addLine(to: CGPoint(x: inset.maxX - topInset, y: inset.minY))
        path.addLine(to: CGPoint(x: inset.maxX, y: inset.maxY))
        path.addLine(to: CGPoint(x: inset.minX, y: inset.maxY))
        path.close()
        
        color.setFill()
        path.fill()
        
        // Vertical center line with small horizontal crossbar
        let vLine = UIBezierPath()
        vLine.move(to: CGPoint(x: centerX, y: inset.minY - 3))
        vLine.addLine(to: CGPoint(x: centerX, y: inset.maxY + 3))
        vLine.lineWidth = 1.5
        color.setStroke()
        vLine.stroke()
        
        let hBar = UIBezierPath()
        let barY = inset.midY
        hBar.move(to: CGPoint(x: centerX - 4, y: barY))
        hBar.addLine(to: CGPoint(x: centerX + 4, y: barY))
        hBar.lineWidth = 1.5
        hBar.stroke()
        
        ctx.restoreGState()
    }
    
    /// Draws the "Horizontal Skew" icon: a sideways trapezoid with a horizontal center line.
    static func drawHorizontalSkewIcon(in rect: CGRect, color: UIColor) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        let inset = rect.insetBy(dx: rect.width * 0.2, dy: rect.height * 0.2)
        let centerY = inset.midY
        
        // Trapezoid: wider on right, narrower on left
        let leftInset: CGFloat = inset.height * 0.15
        let path = UIBezierPath()
        path.move(to: CGPoint(x: inset.minX, y: inset.minY + leftInset))
        path.addLine(to: CGPoint(x: inset.maxX, y: inset.minY))
        path.addLine(to: CGPoint(x: inset.maxX, y: inset.maxY))
        path.addLine(to: CGPoint(x: inset.minX, y: inset.maxY - leftInset))
        path.close()
        
        color.setFill()
        path.fill()
        
        // Horizontal center line with small vertical crossbar
        let hLine = UIBezierPath()
        hLine.move(to: CGPoint(x: inset.minX - 3, y: centerY))
        hLine.addLine(to: CGPoint(x: inset.maxX + 3, y: centerY))
        hLine.lineWidth = 1.5
        color.setStroke()
        hLine.stroke()
        
        let vBar = UIBezierPath()
        let barX = inset.midX
        vBar.move(to: CGPoint(x: barX, y: centerY - 4))
        vBar.addLine(to: CGPoint(x: barX, y: centerY + 4))
        vBar.lineWidth = 1.5
        vBar.stroke()
        
        ctx.restoreGState()
    }
    
    /// Creates a UIImage for the given adjustment type icon.
    static func iconImage(for type: RotationAdjustmentType, size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            switch type {
            case .straighten:
                drawStraightenIcon(in: rect, color: color)
            case .verticalSkew:
                drawVerticalSkewIcon(in: rect, color: color)
            case .horizontalSkew:
                drawHorizontalSkewIcon(in: rect, color: color)
            }
        }
    }
}

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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let ringRect = bounds.insetBy(dx: 2, dy: 2)
        let ringPath = UIBezierPath(ovalIn: ringRect)
        ringLayer.path = ringPath.cgPath
        ringLayer.frame = bounds
        
        progressLayer.path = ringPath.cgPath
        progressLayer.frame = bounds
        
        iconView.frame = bounds.insetBy(dx: bounds.width * 0.22, dy: bounds.height * 0.22)
        valueLabel.frame = bounds
    }
    
    private func setupLayers() {
        // Background ring
        ringLayer.fillColor = UIColor(white: 0.92, alpha: 1.0).cgColor
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
                                                  color: .black)
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
    
    func setValue(_ value: CGFloat, animated: Bool = false) {
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
            refreshIcon(color: .black)
            
        } else {
            // Not selected: smaller appearance, show icon
            iconView.isHidden = false
            valueLabel.isHidden = true
            progressLayer.isHidden = true
            ringLayer.strokeColor = config.ringColor.cgColor
            refreshIcon(color: .black)
        }
    }
    
    private func refreshIcon(color: UIColor) {
        let iconSize = CGSize(width: 24, height: 24)
        iconView.image = SlideDialIconDrawer.iconImage(for: adjustmentType,
                                                        size: iconSize,
                                                        color: color)
    }
}
