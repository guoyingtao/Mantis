//
//  DialConfig.swift
//  Mantis
//
//  Created by Echo on 5/22/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import UIKit

// MARK: - DialConfig
public struct DialConfig {
    public init() {}

    public var margin: Double = 10 {
        didSet {
            assert(margin >= 0)
        }
    }
    
    public var interactable = false
    public var rotationLimitType: RotationLimitType = .limit(angle: CGAngle(degrees: 45))
    public var angleShowLimitType: AngleShowLimitType = .limit(angle: CGAngle(degrees: 40))
    public var rotationCenterType: RotationCenterType = .useDefault
    
    public var numberShowSpan = 1 {
        didSet {
            assert(numberShowSpan > 0)
        }
    }
    
    public var orientation: Orientation = .normal

    public var backgroundColor: UIColor = .clear
    public var bigScaleColor: UIColor = .lightGray
    public var smallScaleColor: UIColor = .lightGray
    public var indicatorColor: UIColor = .lightGray
    public var numberColor: UIColor = .lightGray
    public var centerAxisColor: UIColor = .lightGray

    public var theme: Theme = .dark {
        didSet {
            switch theme {
            case .dark:
                backgroundColor = .clear
                bigScaleColor = .lightGray
                smallScaleColor = .lightGray
                indicatorColor = .lightGray
                numberColor = .lightGray
                centerAxisColor = .lightGray
            case .light:
                backgroundColor = .clear
                bigScaleColor = .darkGray
                smallScaleColor = .darkGray
                indicatorColor = .darkGray
                numberColor = .darkGray
                centerAxisColor = .darkGray
            }
        }
    }

    public enum RotationCenterType {
        case useDefault
        case custom(center: CGPoint)
    }

    public enum AngleShowLimitType {
        case noLimit
        case limit(angle: CGAngle)
    }

    public enum RotationLimitType {
        case noLimit
        case limit(angle: CGAngle)
    }

    public enum Orientation {
        case normal
        case right
        case left
        case upsideDown
    }

    public enum Theme {
        case dark
        case light
    }
}
