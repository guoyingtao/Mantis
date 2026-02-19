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
///
/// The approach for each icon:
/// 1. Draw the shape (circle/trapezoid) in `color` (white)
/// 2. Erase a line through the shape using `backgroundColor` (dark), creating a cutout
///    that stops exactly at the shape's edge
/// 3. Draw the external line segments (outside the shape) in `color` (white)
enum SlideDialIconDrawer {
    
    private static let lineWidth: CGFloat = 1.5
    
    /// Draws the "Straighten" icon: a full circle with a horizontal line.
    /// Inside the circle: line is background-colored (cutout). Outside: white.
    static func drawStraightenIcon(in rect: CGRect, color: UIColor, backgroundColor: UIColor) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        let inset = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.12)
        let centerX = inset.midX
        let centerY = inset.midY
        let radius = inset.width * 0.40
        
        // 1. Draw full circle
        let circle = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY),
                                  radius: radius,
                                  startAngle: 0,
                                  endAngle: .pi * 2,
                                  clockwise: true)
        color.setFill()
        circle.fill()
        
        // 2. Cut a horizontal line through the circle using background color
        let halfLW = lineWidth / 2
        backgroundColor.setFill()
        let cutRect = CGRect(x: centerX - radius,
                             y: centerY - halfLW,
                             width: radius * 2,
                             height: lineWidth)
        ctx.fill(cutRect)
        
        // 3. Draw external line segments in white (outside the circle)
        let lineExtend: CGFloat = radius * 0.45
        color.setStroke()
        
        let leftLine = UIBezierPath()
        leftLine.move(to: CGPoint(x: centerX - radius - lineExtend, y: centerY))
        leftLine.addLine(to: CGPoint(x: centerX - radius, y: centerY))
        leftLine.lineWidth = lineWidth
        leftLine.stroke()
        
        let rightLine = UIBezierPath()
        rightLine.move(to: CGPoint(x: centerX + radius, y: centerY))
        rightLine.addLine(to: CGPoint(x: centerX + radius + lineExtend, y: centerY))
        rightLine.lineWidth = lineWidth
        rightLine.stroke()
        
        ctx.restoreGState()
    }
    
    /// Draws the "Vertical Skew" icon: a trapezoid narrowing at top, with a vertical center line + crossbar.
    /// Inside the trapezoid: line is background-colored (cutout). Outside: white.
    static func drawVerticalSkewIcon(in rect: CGRect, color: UIColor, backgroundColor: UIColor) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        let inset = rect.insetBy(dx: rect.width * 0.21, dy: rect.height * 0.21)
        let centerX = inset.midX
        let centerY = inset.midY
        
        let topInset: CGFloat = inset.width * 0.18
        
        // 1. Draw trapezoid
        let trapezoid = UIBezierPath()
        trapezoid.move(to: CGPoint(x: inset.minX + topInset, y: inset.minY))
        trapezoid.addLine(to: CGPoint(x: inset.maxX - topInset, y: inset.minY))
        trapezoid.addLine(to: CGPoint(x: inset.maxX, y: inset.maxY))
        trapezoid.addLine(to: CGPoint(x: inset.minX, y: inset.maxY))
        trapezoid.close()
        
        color.setFill()
        trapezoid.fill()
        
        // 2. Cut a vertical line through the trapezoid using background color
        let halfLW = lineWidth / 2
        backgroundColor.setFill()
        let cutRect = CGRect(x: centerX - halfLW,
                             y: inset.minY,
                             width: lineWidth,
                             height: inset.height)
        ctx.fill(cutRect)
        
        // 3. Draw external line segments in white (outside the trapezoid)
        let lineExtend: CGFloat = 3.5
        color.setStroke()
        
        let topLine = UIBezierPath()
        topLine.move(to: CGPoint(x: centerX, y: inset.minY - lineExtend))
        topLine.addLine(to: CGPoint(x: centerX, y: inset.minY))
        topLine.lineWidth = lineWidth
        topLine.stroke()
        
        let botLine = UIBezierPath()
        botLine.move(to: CGPoint(x: centerX, y: inset.maxY))
        botLine.addLine(to: CGPoint(x: centerX, y: inset.maxY + lineExtend))
        botLine.lineWidth = lineWidth
        botLine.stroke()
        
        // Small horizontal crossbar at center (white, inside the trapezoid)
        let hBar = UIBezierPath()
        hBar.move(to: CGPoint(x: centerX - 3.5, y: centerY))
        hBar.addLine(to: CGPoint(x: centerX + 3.5, y: centerY))
        hBar.lineWidth = lineWidth
        color.setStroke()
        hBar.stroke()
        
        ctx.restoreGState()
    }
    
    /// Draws the "Horizontal Skew" icon: a sideways trapezoid (narrower on left),
    /// with a horizontal center line + crossbar.
    /// Inside the trapezoid: line is background-colored (cutout). Outside: white.
    static func drawHorizontalSkewIcon(in rect: CGRect, color: UIColor, backgroundColor: UIColor) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        let inset = rect.insetBy(dx: rect.width * 0.21, dy: rect.height * 0.21)
        let centerX = inset.midX
        let centerY = inset.midY
        
        let leftInset: CGFloat = inset.height * 0.18
        
        // 1. Draw trapezoid
        let trapezoid = UIBezierPath()
        trapezoid.move(to: CGPoint(x: inset.minX, y: inset.minY + leftInset))
        trapezoid.addLine(to: CGPoint(x: inset.maxX, y: inset.minY))
        trapezoid.addLine(to: CGPoint(x: inset.maxX, y: inset.maxY))
        trapezoid.addLine(to: CGPoint(x: inset.minX, y: inset.maxY - leftInset))
        trapezoid.close()
        
        color.setFill()
        trapezoid.fill()
        
        // 2. Cut a horizontal line through the trapezoid using background color
        let halfLW = lineWidth / 2
        backgroundColor.setFill()
        let cutRect = CGRect(x: inset.minX,
                             y: centerY - halfLW,
                             width: inset.width,
                             height: lineWidth)
        ctx.fill(cutRect)
        
        // 3. Draw external line segments in white (outside the trapezoid)
        let lineExtend: CGFloat = 3.5
        color.setStroke()
        
        let leftLine = UIBezierPath()
        leftLine.move(to: CGPoint(x: inset.minX - lineExtend, y: centerY))
        leftLine.addLine(to: CGPoint(x: inset.minX, y: centerY))
        leftLine.lineWidth = lineWidth
        leftLine.stroke()
        
        let rightLine = UIBezierPath()
        rightLine.move(to: CGPoint(x: inset.maxX, y: centerY))
        rightLine.addLine(to: CGPoint(x: inset.maxX + lineExtend, y: centerY))
        rightLine.lineWidth = lineWidth
        rightLine.stroke()
        
        // Small vertical crossbar at center (white, inside the trapezoid)
        let vBar = UIBezierPath()
        vBar.move(to: CGPoint(x: centerX, y: centerY - 3.5))
        vBar.addLine(to: CGPoint(x: centerX, y: centerY + 3.5))
        vBar.lineWidth = lineWidth
        color.setStroke()
        vBar.stroke()
        
        ctx.restoreGState()
    }
    
    /// Creates a UIImage for the given adjustment type icon.
    static func iconImage(for type: RotationAdjustmentType,
                          size: CGSize,
                          color: UIColor,
                          backgroundColor: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            switch type {
            case .straighten:
                drawStraightenIcon(in: rect, color: color, backgroundColor: backgroundColor)
            case .verticalSkew:
                drawVerticalSkewIcon(in: rect, color: color, backgroundColor: backgroundColor)
            case .horizontalSkew:
                drawHorizontalSkewIcon(in: rect, color: color, backgroundColor: backgroundColor)
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
