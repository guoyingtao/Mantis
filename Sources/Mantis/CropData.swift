//
//  TypeAlias.swift
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

struct CropState: Equatable {
    var rotationType: ImageRotationType
    var degrees: CGFloat
    var aspectRatioLockEnabled: Bool
    var aspectRato: CGFloat
    var flipOddTimes: Bool
    var transformation: Transformation
    
    static func == (lhs: CropState, rhs: CropState) -> Bool {
        return lhs.rotationType == rhs.rotationType
        && lhs.degrees == rhs.degrees
        && lhs.aspectRatioLockEnabled == rhs.aspectRatioLockEnabled
        && lhs.aspectRato == rhs.aspectRato
        && lhs.flipOddTimes == rhs.flipOddTimes
        && lhs.transformation == rhs.transformation
    }
}

public struct Transformation: Equatable {
    public var offset: CGPoint
    public var rotation: CGFloat
    public var scale: CGFloat
    public var isManuallyZoomed: Bool
    public var initialMaskFrame: CGRect
    public var maskFrame: CGRect
    public var cropWorkbenchViewBounds: CGRect
    public var horizontallyFlipped: Bool
    public var verticallyFlipped: Bool
    
    public init(offset: CGPoint,
                rotation: CGFloat,
                scale: CGFloat,
                isManuallyZoomed: Bool,
                initialMaskFrame: CGRect,
                maskFrame: CGRect,
                cropWorkbenchViewBounds: CGRect,
                horizontallyFlipped: Bool,
                verticallyFlipped: Bool) {
        self.offset = offset
        self.rotation = rotation
        self.scale = scale
        self.isManuallyZoomed = isManuallyZoomed
        self.initialMaskFrame = initialMaskFrame
        self.maskFrame = maskFrame
        self.cropWorkbenchViewBounds = cropWorkbenchViewBounds
        self.horizontallyFlipped = horizontallyFlipped
        self.verticallyFlipped = verticallyFlipped
    }
    
    public static func == (lhs: Transformation, rhs: Transformation) -> Bool {
        return lhs.offset == rhs.offset
        && lhs.rotation == rhs.rotation
        && lhs.scale == rhs.scale
        && lhs.isManuallyZoomed == rhs.isManuallyZoomed
        && lhs.initialMaskFrame == rhs.initialMaskFrame
        && lhs.maskFrame == rhs.maskFrame
        && lhs.cropWorkbenchViewBounds == rhs.cropWorkbenchViewBounds
        && lhs.horizontallyFlipped == rhs.horizontallyFlipped
        && lhs.verticallyFlipped == rhs.verticallyFlipped
    }
}

public struct CropRegion: Equatable {
    public var topLeft: CGPoint
    public var topRight: CGPoint
    public var bottomLeft: CGPoint
    public var bottomRight: CGPoint
    
    public init(topLeft: CGPoint,
                topRight: CGPoint,
                bottomLeft: CGPoint,
                bottomRight: CGPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
    }
    
    public static func == (lhs: CropRegion, rhs: CropRegion) -> Bool {
        return lhs.topLeft == rhs.topLeft
        && lhs.topRight == rhs.topRight
        && lhs.bottomLeft == rhs.bottomLeft
        && lhs.bottomRight == rhs.bottomRight
    }
}

public typealias CropInfo = (
    translation: CGPoint,
    rotation: CGFloat,
    scaleX: CGFloat,
    scaleY: CGFloat,
    cropSize: CGSize,
    imageViewSize: CGSize,
    cropRegion: CropRegion
)

typealias CropOutput = (
    croppedImage: UIImage?,
    transformation: Transformation,
    cropInfo: CropInfo
)
