//
//  Enum.swift
//  Mantis
//
//  Created by Echo on 07/07/22.
//  Copyright © 2022 Echo. All rights reserved.
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

public enum PresetTransformationType {
    case none
    case presetInfo(info: Transformation)
    case presetNormalizedInfo(normalizedInfo: CGRect)
}

public enum PresetFixedRatioType {
    /** When choose alwaysUsingOnePresetFixedRatio, fixed-ratio setting button does not show.
     */
    case alwaysUsingOnePresetFixedRatio(ratio: Double = 0)
    case canUseMultiplePresetFixedRatio(defaultRatio: Double = 0)
}

public enum CropMaskVisualEffectType {
    case blurDark
    case dark
    case light
    case custom(color: UIColor)
    case `default`
}

public enum CropShapeType: Hashable {
    case rect

    /**
      The ratio of the crop mask will always be 1:1.
     ### Notice
     It equals cropShapeType = .rect
     and presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
     */
    case square

    /**
     When maskOnly is true, the cropped image is kept rect
     */
    case ellipse(maskOnly: Bool = false)

    /**
      The ratio of the crop mask will always be 1:1 and when maskOnly is true, the cropped image is kept rect.
     ### Notice
     It equals cropShapeType = .ellipse and presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
     */
    case circle(maskOnly: Bool = false)

    /**
     When maskOnly is true, the cropped image is kept rect
     */
    case roundedRect(radiusToShortSide: CGFloat, maskOnly: Bool = false)

    case diamond(maskOnly: Bool = false)

    case heart(maskOnly: Bool = false)

    case polygon(sides: Int, offset: CGFloat = 0, maskOnly: Bool = false)

    /**
      Each point should have normalized values whose range is 0...1
     */
    case path(points: [CGPoint], maskOnly: Bool = false)
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .rect:
            hasher.combine(0)
        case .square:
            hasher.combine(1)
        case .ellipse(let maskOnly):
            hasher.combine(2)
            hasher.combine(maskOnly)
        case .circle(let maskOnly):
            hasher.combine(3)
            hasher.combine(maskOnly)
        case .roundedRect(let radiusToShortSide, let maskOnly):
            hasher.combine(4)
            hasher.combine(radiusToShortSide)
            hasher.combine(maskOnly)
        case .diamond(let maskOnly):
            hasher.combine(5)
            hasher.combine(maskOnly)
        case .heart(let maskOnly):
            hasher.combine(6)
            hasher.combine(maskOnly)
        case .polygon(let sides, let offset, let maskOnly):
            hasher.combine(7)
            hasher.combine(sides)
            hasher.combine(offset)
            hasher.combine(maskOnly)
        case .path(let points, let maskOnly):
            hasher.combine(8)
            for point in points {
                hasher.combine(point.x)
                hasher.combine(point.y)
            }
            hasher.combine(maskOnly)
        }
    }
}

public enum RatioCandidatesShowType {
    case presentRatioListFromButton
    case alwaysShowRatioList
}

public enum FixedRatiosShowType {
    case adaptive
    case horizontal
    case vertical
}

enum RotateBy90DegreeType {
    case clockwise
    case counterClockwise
    
    mutating func toggle() {
        if self == .clockwise {
            self = .counterClockwise
        } else {
            self = .clockwise
        }
    }
}

public enum CropAuxiliaryIndicatorStyleType {
    case normal
    case transparent
}

enum CropViewAuxiliaryIndicatorHandleType: Int {
    case none
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
}

enum AutoLayoutPriorityType: Float {
    case high = 10000
    case low = 1
}

enum Constants {
    static let rotationDegreeLimit: CGFloat = 45
}
