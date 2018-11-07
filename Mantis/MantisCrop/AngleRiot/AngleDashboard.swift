//
//  AngleDashboard.swift
//  Mantis
//
//  Created by Echo on 10/21/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class AngleDashboard: UIView {
    
    var radiansLimit: CGFloat = 45 * CGFloat.pi / 180
    
    let showRadiansLimit: CGFloat = 37.5 * CGFloat.pi / 180
    let pointerHeight: CGFloat = 8
    let spanBetweenDialPlateAndPointer: CGFloat = 6
    
    private var dialPlate: AngleDialPlate!
    private var pointer: CAShapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        
        var dialPlateShowHeight = frame.height - pointerHeight - spanBetweenDialPlateAndPointer
        var r = dialPlateShowHeight / (1 - cos(showRadiansLimit))
        
        if r * 2 * sin(showRadiansLimit) > frame.width {
            r = (frame.width / 2) / sin(showRadiansLimit)
            dialPlateShowHeight = r - r * cos(showRadiansLimit)
        }

        let dialPlateLength = 2 * r
        let dialPlateFrame = CGRect(x: (frame.width - dialPlateLength) / 2, y: -(dialPlateLength - dialPlateShowHeight), width: dialPlateLength, height: dialPlateLength)
        
        dialPlate =  AngleDialPlate(frame: dialPlateFrame)
    
        addSubview(dialPlate)
        
        setupPointer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupPointer(){
        let path = CGMutablePath()
        
        let pointerEdgeLength: CGFloat = pointerHeight * sqrt(2)
        
        let pointTop = CGPoint(x: bounds.width/2, y: bounds.height - pointerHeight)
        let pointLeft = CGPoint(x: bounds.width/2 - pointerEdgeLength / 2, y: pointTop.y + pointerHeight)
        let pointRight = CGPoint(x: bounds.width/2 + pointerEdgeLength / 2, y: pointLeft.y)
        
        path.move(to: pointTop)
        path.addLine(to: pointLeft)
        path.addLine(to: pointRight)
        path.addLine(to: pointTop)
        pointer.fillColor = UIColor.lightGray.cgColor
        pointer.path = path
        layer.addSublayer(pointer)
    }
    
    func getRotationCenter() -> CGPoint {
        return CGPoint(x: dialPlate.frame.midX , y: dialPlate.frame.midY)
    }
    
    @discardableResult
    func rotateDialPlate(byRadians radians: CGFloat) -> Bool {
        
        if (getRotationRadians() * radians) > 0 && abs(getRotationRadians() + radians) >= radiansLimit {
            return false
        } else {
            dialPlate.transform = dialPlate.transform.rotated(by: radians)
            return true
        }        
    }
    
    func rotateDialPlate(toRadians radians: CGFloat, animated: Bool = false) {
        guard abs(radians) < radiansLimit else {
            return
        }
        
        func rotate() {
            dialPlate.transform = CGAffineTransform(rotationAngle: radians)
        }
        
        if animated {
            UIView.animate(withDuration: 0.5) {
                rotate()
            }
        } else {
            rotate()
        }
    }
    
    func getRotationRadians() -> CGFloat {
        return CGFloat(atan2f(Float(dialPlate.transform.b), Float(dialPlate.transform.a)))
    }
    
    func getRotationDegrees() -> CGFloat {
        return getRotationRadians() * 180 / CGFloat.pi
    }
}
