//
//  AngleDashboard.swift
//  Mantis
//
//  Created by Echo on 10/21/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

fileprivate let bigDegreeScaleNumber = 36
fileprivate let smallDegreeScaleNumber = bigDegreeScaleNumber * 4

class AngleDashboard: UIView {
    
    var dialPlate: AngleDialPlate!
    var pointer: CAShapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .gray
        clipsToBounds = true
        
        let dialPlateFrame = CGRect(x: 0, y: -frame.width * 0.85, width: frame.width, height: frame.width)
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
    
}
