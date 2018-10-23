//
//  CropMaskProtocal.swift
//  Mantis
//
//  Created by Echo on 10/22/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation
import UIKit

protocol CropMaskProtocal where Self: UIView {
    func initialize(targetCropRect cropRect: CGRect)
    func setMask()
    func adaptMaskTo(match cropRect: CGRect)
}

extension CropMaskProtocal {
    func initialize(targetCropRect cropRect: CGRect) {
        setInitialFrame()
        setMask()
        adaptMaskTo(match: cropRect)
    }
    
    private func setInitialFrame() {
        let initialLength: CGFloat = 10000
        let width = initialLength
        let height = initialLength
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let x = (screenWidth - width) / 2
        let y = (screenHeight - height) / 2
        
        self.frame = CGRect(x: x, y: y, width: width, height: height)
    }
    
    func adaptMaskTo(match cropRect: CGRect) {
        
    }
    
    func createOverLayer(opacity: Float) -> CAShapeLayer {
        let minOverLayerUnit: CGFloat = 10
        let x = self.frame.midX - minOverLayerUnit / 2
        let y = self.frame.midY - minOverLayerUnit / 2
        let initialRect = CGRect(x: x, y: y, width: minOverLayerUnit, height: minOverLayerUnit)
        
        let path = UIBezierPath(rect: self.bounds)
        let innerPath = UIBezierPath(ovalIn: initialRect)
        path.append(innerPath)
        path.usesEvenOddFillRule = true
        
        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = UIColor.black.cgColor
        fillLayer.opacity = opacity
        return fillLayer
    }
}
