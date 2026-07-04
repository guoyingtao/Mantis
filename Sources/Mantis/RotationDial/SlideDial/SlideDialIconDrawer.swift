//
//  SlideDialIconDrawer.swift
//  Mantis
//
//  Extracted from SlideDialTypeButton.swift
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
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
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
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
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
        
        // Small horizontal crossbar at center, split to avoid cutout zone
        let gap = halfLW + 0.5
        color.setStroke()
        
        let hBarLeft = UIBezierPath()
        hBarLeft.move(to: CGPoint(x: centerX - 3.5, y: centerY))
        hBarLeft.addLine(to: CGPoint(x: centerX - gap, y: centerY))
        hBarLeft.lineWidth = lineWidth
        hBarLeft.stroke()
        
        let hBarRight = UIBezierPath()
        hBarRight.move(to: CGPoint(x: centerX + gap, y: centerY))
        hBarRight.addLine(to: CGPoint(x: centerX + 3.5, y: centerY))
        hBarRight.lineWidth = lineWidth
        hBarRight.stroke()
        
        ctx.restoreGState()
    }
    
    /// Draws the "Horizontal Skew" icon: a sideways trapezoid (narrower on left),
    /// with a horizontal center line + crossbar.
    /// Inside the trapezoid: line is background-colored (cutout). Outside: white.
    static func drawHorizontalSkewIcon(in rect: CGRect, color: UIColor, backgroundColor: UIColor) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
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
        
        // Small vertical crossbar at center, split to avoid cutout zone
        let gap = halfLW + 0.5
        color.setStroke()
        
        let vBarTop = UIBezierPath()
        vBarTop.move(to: CGPoint(x: centerX, y: centerY - 3.5))
        vBarTop.addLine(to: CGPoint(x: centerX, y: centerY - gap))
        vBarTop.lineWidth = lineWidth
        vBarTop.stroke()
        
        let vBarBottom = UIBezierPath()
        vBarBottom.move(to: CGPoint(x: centerX, y: centerY + gap))
        vBarBottom.addLine(to: CGPoint(x: centerX, y: centerY + 3.5))
        vBarBottom.lineWidth = lineWidth
        vBarBottom.stroke()
        
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
