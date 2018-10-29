//
//  AngleDashboard.swift
//  Mantis
//
//  Created by Echo on 10/21/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class AngleDashboard: UIView {
    
    var angleLimit:CGFloat = 45
    
    private var dialPlate: AngleDialPlate!
    private var pointer: CAShapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        
        clipsToBounds = true
        
        let dialPlateFrame = CGRect(x: 0, y: -frame.width * 0.9, width: frame.width, height: frame.width)
        dialPlate =  AngleDialPlate(frame: dialPlateFrame)
        addSubview(dialPlate)
        
        setupPointer(withDialPlateMaxY: dialPlate.frame.maxY)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupPointer(withDialPlateMaxY dialPlateMaxY: CGFloat){
        let path = CGMutablePath()
        
        let distanceFromDialPlateBottom: CGFloat = 0
        let pointerEdgeLength: CGFloat = 10
        let pointerHeight = pointerEdgeLength / sqrt(2)
        
        let pointTop = CGPoint(x: bounds.width/2, y: dialPlateMaxY + distanceFromDialPlateBottom)
        let pointLeft = CGPoint(x: bounds.width/2 - pointerEdgeLength / 2, y: pointTop.y + pointerHeight)
        let pointRight = CGPoint(x: bounds.width/2 + pointerEdgeLength / 2, y: pointLeft.y)
        
        path.move(to: pointTop)
        path.addLine(to: pointLeft)
        path.addLine(to: pointRight)
        path.addLine(to: pointTop)
        pointer.fillColor = UIColor.white.cgColor
        pointer.path = path
        layer.addSublayer(pointer)
    }
    
    func getRotationCenter() -> CGPoint {
        return CGPoint(x: dialPlate.frame.midX , y: dialPlate.frame.midY)
    }
    
    func rotateDialPlate(by angle: CGFloat) -> Bool {
        if abs(getRotationAngle() + angle) >= angleLimit {
            return false
        } else {
            dialPlate.transform = dialPlate.transform.rotated(by: angle)
            return true
        }        
    }
    
    func getRotationAngle() -> CGFloat {
        let radians = CGFloat(atan2f(Float(dialPlate.transform.b), Float(dialPlate.transform.a)))
        let degrees = radians * (180 / CGFloat.pi)
        return degrees
    }
}
