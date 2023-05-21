//
//  CustomWaitingIndicator.swift
//  MantisExample
//
//  Created by Yingtao Guo on 2/24/23.
//  Copyright © 2023 Echo. All rights reserved.
//

import Mantis
import UIKit

class CustomWaitingIndicator: UIView, Mantis.ActivityIndicatorProtocol {
    
    private let circleLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        let circlePath = UIBezierPath(ovalIn: bounds)
        
        circleLayer.path = circlePath.cgPath
        circleLayer.strokeColor = UIColor.blue.cgColor
        circleLayer.lineWidth = 2
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeEnd = 0.25
        circleLayer.frame = bounds
        
        layer.addSublayer(circleLayer)
    }
    
    func startAnimating() {
        circleLayer.removeAllAnimations()
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.duration = 1
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = CGFloat.pi * 2
        rotationAnimation.repeatCount = .infinity
        circleLayer.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    func stopAnimating() {
        circleLayer.removeAnimation(forKey: "rotationAnimation")
    }
}
