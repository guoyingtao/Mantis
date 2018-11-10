//
//  RotationAngleIndicator.swift
//  Mantis
//
//  Created by Echo on 10/24/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

fileprivate let bigDegreeScaleNumber = 36
fileprivate let smallDegreeScaleNumber = bigDegreeScaleNumber * 5
fileprivate let margin: CGFloat = 0
fileprivate let spaceBetweenScaleAndNumber: CGFloat = 10

class RotationAngleIndicator: UIView {

    let smallDotLayer:CAReplicatorLayer = {
        var r = CAReplicatorLayer()
        r.instanceCount = smallDegreeScaleNumber
        r.instanceTransform =
            CATransform3DMakeRotation(
                2 * CGFloat.pi / CGFloat(r.instanceCount),
                0,0,1)
        
        return r
    }()
    
    let bigDotLayer:CAReplicatorLayer = {
        var r = CAReplicatorLayer()
        r.instanceCount = bigDegreeScaleNumber
        r.instanceTransform =
            CATransform3DMakeRotation(
                2 * CGFloat.pi / CGFloat(r.instanceCount),
                0,0,1)
        
        return r
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func getSmallScaleMark() -> CALayer {
        let mark = CAShapeLayer()
        mark.frame = CGRect(x: 0, y: 0, width: 2, height: 2)
        mark.path = UIBezierPath(ovalIn: mark.bounds).cgPath
        mark.fillColor = UIColor.lightGray.cgColor
        
        return mark
    }
    
    private func getBigScaleMark() -> CALayer {
        let mark = CAShapeLayer()
        mark.frame = CGRect(x: 0, y: 0, width: 4, height: 4)
        mark.path = UIBezierPath(ovalIn: mark.bounds).cgPath
        mark.fillColor = UIColor.lightGray.cgColor
        
        return mark
    }
    
    private func setupAngleNumber() {
        let numberColor = UIColor.lightGray
        let numberFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption2)
        
        let cgFont = CTFontCreateWithName(numberFont.fontName as CFString, numberFont.pointSize/2, nil)
        
        let numberPlateLayer = CALayer()
        numberPlateLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        numberPlateLayer.frame = self.bounds
        self.layer.addSublayer(numberPlateLayer)
        
        let origin = numberPlateLayer.center
        let startPos = CGPoint(x: numberPlateLayer.bounds.midX, y: numberPlateLayer.bounds.maxY - margin - spaceBetweenScaleAndNumber)
        let step = (2 * CGFloat.pi) / CGFloat(bigDegreeScaleNumber)
        for i in (0 ..< bigDegreeScaleNumber){
            let numberLayer = CATextLayer()
            numberLayer.bounds.size = CGSize(width: 20, height: 15)
            numberLayer.fontSize = numberFont.pointSize
            numberLayer.alignmentMode = CATextLayerAlignmentMode.center
            numberLayer.contentsScale = UIScreen.main.scale
            numberLayer.font = cgFont
            let angle = (i > bigDegreeScaleNumber / 2 ? i - bigDegreeScaleNumber : i) * 10
            numberLayer.string = "\(angle)"
            numberLayer.foregroundColor = numberColor.cgColor
            
            let stepChange = CGFloat(i) * step
            numberLayer.position = CGVector(from:origin, to:startPos).rotate(-stepChange).add(origin.vector).point.checked
            
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
    
    private func setup() {
        setupSmallScaleMarks()
        setupBigScaleMarks()
        setupAngleNumber()
    }

}

extension CALayer{
    var size:CGSize{
        get{ return self.bounds.size.checked }
        set{ return self.bounds.size = newValue }
    }
    var occupation:(CGSize, CGPoint) {
        get{ return (size, self.center.checked) }
        set{ size = newValue.0; position = newValue.1 }
    }
    var center:CGPoint{
        get{ return self.bounds.center.checked }
    }
}
