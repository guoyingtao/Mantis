//
//  RotationDailPlate.swift
//  Puffer
//
//  Created by Echo on 10/24/18.
//  Copyright © 2018 Echo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

private let bigDegreeScaleNumber = 36
private let smallDegreeScaleNumber = bigDegreeScaleNumber * 5
private let margin: CGFloat = 0
private let spaceBetweenScaleAndNumber: CGFloat = 10

class RotationDialPlate: UIView {

    let smallDotLayer: CAReplicatorLayer = {
        var layer = CAReplicatorLayer()
        layer.instanceCount = smallDegreeScaleNumber
        layer.instanceTransform =
            CATransform3DMakeRotation(
                2 * CGFloat.pi / CGFloat(layer.instanceCount),
                0, 0, 1)
        
        return layer
    }()
    
    let bigDotLayer: CAReplicatorLayer = {
        var layer = CAReplicatorLayer()
        layer.instanceCount = bigDegreeScaleNumber
        layer.instanceTransform =
            CATransform3DMakeRotation(
                2 * CGFloat.pi / CGFloat(layer.instanceCount),
                0, 0, 1)
        
        return layer
    }()
    
    var dialConfig = Mantis.Config().cropViewConfig.dialConfig
    
    init(frame: CGRect, dialConfig: DialConfig) {
        super.init(frame: frame)
        self.dialConfig = dialConfig
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func getSmallScaleMark() -> CALayer {
        let mark = CAShapeLayer()
        mark.frame = CGRect(x: 0, y: 0, width: 2, height: 2)
        mark.path = UIBezierPath(ovalIn: mark.bounds).cgPath
        mark.fillColor = dialConfig.smallScaleColor.cgColor
        
        return mark
    }
    
    private func getBigScaleMark() -> CALayer {
        let mark = CAShapeLayer()
        mark.frame = CGRect(x: 0, y: 0, width: 4, height: 4)
        mark.path = UIBezierPath(ovalIn: mark.bounds).cgPath
        
        mark.fillColor = dialConfig.smallScaleColor.cgColor
        
        return mark
    }
    
    private func setupAngleNumber() {
        let numberFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption2)
        let cgFont = CTFontCreateUIFontForLanguage(.label, numberFont.pointSize/2, nil)
        
        let numberPlateLayer = CALayer()
        numberPlateLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        numberPlateLayer.frame = self.bounds
        self.layer.addSublayer(numberPlateLayer)
        
        let origin = CGPoint(x: numberPlateLayer.frame.midX, y: numberPlateLayer.frame.midY)
        let startPos = CGPoint(x: numberPlateLayer.bounds.midX, y: numberPlateLayer.bounds.maxY - margin - spaceBetweenScaleAndNumber)
        let step = (2 * CGFloat.pi) / CGFloat(bigDegreeScaleNumber)
        
        for index in (0 ..< bigDegreeScaleNumber) {
            
            guard index % dialConfig.numberShowSpan == 0 else {
                continue
            }
            
            let numberLayer = CATextLayer()
            numberLayer.bounds.size = CGSize(width: 30, height: 15)
            numberLayer.fontSize = numberFont.pointSize
            numberLayer.alignmentMode = CATextLayerAlignmentMode.center
            numberLayer.contentsScale = UIScreen.main.scale
            numberLayer.font = cgFont
            let angle = (index > bigDegreeScaleNumber / 2 ? index - bigDegreeScaleNumber : index) * 10
            numberLayer.string = "\(angle)"
            numberLayer.foregroundColor = dialConfig.numberColor.cgColor
            
            let stepChange = CGFloat(index) * step
            numberLayer.position = CGVector(fromPoint: origin, toPoint: startPos)
                .rotate(-stepChange)
                .add(origin.vector)
                .point
                .checked
            
            numberLayer.transform = CATransform3DMakeRotation(-stepChange, 0, 0, 1)            
            numberPlateLayer.addSublayer(numberLayer)
        }
    }
    
    private func setupSmallScaleMarks() {
        smallDotLayer.frame = self.bounds
        smallDotLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let smallScaleMark = getSmallScaleMark()
        smallScaleMark.position = CGPoint(x: smallDotLayer.bounds.midX, y: margin)
        smallDotLayer.addSublayer(smallScaleMark)
        
        self.layer.addSublayer(smallDotLayer)
    }
    
    private func setupBigScaleMarks() {
        bigDotLayer.frame = self.bounds
        bigDotLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let bigScaleMark = getBigScaleMark()
        bigScaleMark.position = CGPoint(x: bigDotLayer.bounds.midX, y: margin)
        bigDotLayer.addSublayer(bigScaleMark)
        self.layer.addSublayer(bigDotLayer)
    }
    
    private func setCenterPart() {
        let layer = CAShapeLayer()
        let radius: CGFloat = 4
        layer.frame = CGRect(x: (self.layer.bounds.width - radius) / 2 ,
                             y: (self.layer.bounds.height - radius) / 2,
                             width: radius,
                             height: radius)
        layer.path = UIBezierPath(ovalIn: layer.bounds).cgPath
        layer.fillColor = dialConfig.centerAxisColor.cgColor
        
        self.layer.addSublayer(layer)
    }
    
    private func setup() {
        setupSmallScaleMarks()
        setupBigScaleMarks()
        setupAngleNumber()
        setCenterPart()
    }
}
