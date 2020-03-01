//
//  DialConfig.swift
//  Mantis
//
//  Created by Echo on 5/24/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import Foundation
import UIKit

enum DialConfig {
    struct Config {
        public init() {}
        
        public var margin: Double = 10
        public var interactable = false
        public var rotationLimitType: RotationLimitType = .noLimit
        public var angleShowLimitType: AnglehowLimitType = .noLimit
        public var rotationCenterType: RotationCenterType = .useDefault
        public var numberShowSpan = 2
        public var orientation: Orientation = .normal
        
        public var backgroundColor: UIColor = .black
        public var bigScaleColor: UIColor = .lightGray
        public var smallScaleColor: UIColor = .lightGray
        public var indicatorColor: UIColor = .lightGray
        public var numberColor: UIColor = .lightGray
        public var centerAxisColor: UIColor = .lightGray
        
        public var theme: Theme = .dark {
            didSet {
                switch theme {
                case .dark:
                    backgroundColor = .black
                    bigScaleColor = .lightGray
                    smallScaleColor = .lightGray
                    indicatorColor = .lightGray
                    numberColor = .lightGray
                    centerAxisColor = .lightGray
                case .light:
                    backgroundColor = .white
                    bigScaleColor = .darkGray
                    smallScaleColor = .darkGray
                    indicatorColor = .darkGray
                    numberColor = .darkGray
                    centerAxisColor = .darkGray
                }
            }
        }
    }
    
    enum RotationCenterType {
        case useDefault
        case custom(CGPoint)
    }
    
    enum RotationLimitType {
        case noLimit
        case limit(angle: CGAngle)
    }
    
    enum AnglehowLimitType {
        case noLimit
        case limit(angle: CGAngle)
    }
    
    enum Orientation {
        case normal
        case right
        case left
        case upsideDown
    }
    
    enum Theme {
        case dark
        case light
    }
}
