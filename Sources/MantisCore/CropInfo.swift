//
//  CropInfo.swift
//  MantisCore
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

import CoreGraphics
import QuartzCore

public struct CropRegion: Equatable, Sendable, Codable {
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

public struct CropInfo: Sendable, Codable {
    public var translation: CGPoint
    public var rotation: CGFloat
    public var scaleX: CGFloat
    public var scaleY: CGFloat
    public var cropSize: CGSize
    public var imageViewSize: CGSize
    public var cropRegion: CropRegion
    public var horizontalSkewDegrees: CGFloat
    public var verticalSkewDegrees: CGFloat

    /// View-hierarchy state captured at crop time, needed only to reconstruct
    /// and invert the exact on-screen transform in the perspective / CIImage
    /// crop paths. Populated by `CropView.getCropInfo()`; `nil` for a `CropInfo`
    /// a caller builds directly (those crop paths then return `nil` rather than
    /// producing a wrong result). Kept out of the public API so the public
    /// surface carries only semantic crop parameters.
    package var viewReconstruction: ViewReconstruction?

    public init(
        translation: CGPoint,
        rotation: CGFloat,
        scaleX: CGFloat,
        scaleY: CGFloat,
        cropSize: CGSize,
        imageViewSize: CGSize,
        cropRegion: CropRegion,
        horizontalSkewDegrees: CGFloat = 0,
        verticalSkewDegrees: CGFloat = 0
    ) {
        self.translation = translation
        self.rotation = rotation
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.cropSize = cropSize
        self.imageViewSize = imageViewSize
        self.cropRegion = cropRegion
        self.horizontalSkewDegrees = horizontalSkewDegrees
        self.verticalSkewDegrees = verticalSkewDegrees
        self.viewReconstruction = nil
    }
}

extension CropInfo {
    /// Captured scroll-view / layer state that lets the perspective and
    /// large-image (CIImage) crop paths rebuild and invert the exact transform
    /// used on screen. Package-internal — not part of the public crop API.
    package struct ViewReconstruction: Sendable {
        /// The CATransform3D sublayerTransform used in the preview for perspective
        /// skew (perspective rotation, centering, compensating scale). Identity
        /// when no skew is applied.
        package var skewSublayerTransform: CATransform3D
        /// The scroll view's content offset during crop.
        package var scrollContentOffset: CGPoint
        /// The scroll view's visible bounds size during crop.
        package var scrollBoundsSize: CGSize
        /// The image container's frame in scroll content coordinates during crop.
        package var imageContainerFrame: CGRect
        /// The scroll view's actual 2D transform (rotation + flip), inverted by the
        /// perspective crop path instead of reconstructing it from decomposed
        /// rotation / scale values.
        package var scrollViewTransform: CGAffineTransform

        package init(skewSublayerTransform: CATransform3D,
                     scrollContentOffset: CGPoint,
                     scrollBoundsSize: CGSize,
                     imageContainerFrame: CGRect,
                     scrollViewTransform: CGAffineTransform) {
            self.skewSublayerTransform = skewSublayerTransform
            self.scrollContentOffset = scrollContentOffset
            self.scrollBoundsSize = scrollBoundsSize
            self.imageContainerFrame = imageContainerFrame
            self.scrollViewTransform = scrollViewTransform
        }
    }
}

/// `Codable` support so a `CropInfo` (including the internal view-reconstruction
/// state needed for perspective / large-image crops) can be persisted and
/// restored across app sessions. `CropInfo` and `CropRegion` get synthesized
/// conformances; `ViewReconstruction` needs a manual one because `CATransform3D`
/// and `CGAffineTransform` are not `Codable`. Their coefficients are boxed into
/// private `Codable` structs rather than adding `Codable` conformances to the
/// CoreGraphics/QuartzCore types themselves — a library-level retroactive
/// conformance there would clash if the host app (or another dependency) added
/// the same one.
extension CropInfo.ViewReconstruction: Codable {
    // swiftlint:disable identifier_name
    /// The six coefficients of a `CGAffineTransform`.
    private struct AffineTransformBox: Codable {
        var a, b, c, d, tx, ty: CGFloat

        init(_ transform: CGAffineTransform) {
            a = transform.a
            b = transform.b
            c = transform.c
            d = transform.d
            tx = transform.tx
            ty = transform.ty
        }

        var transform: CGAffineTransform {
            CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
        }
    }

    /// The sixteen coefficients of a `CATransform3D`.
    private struct Transform3DBox: Codable {
        var m11, m12, m13, m14: CGFloat
        var m21, m22, m23, m24: CGFloat
        var m31, m32, m33, m34: CGFloat
        var m41, m42, m43, m44: CGFloat

        init(_ transform: CATransform3D) {
            m11 = transform.m11; m12 = transform.m12; m13 = transform.m13; m14 = transform.m14
            m21 = transform.m21; m22 = transform.m22; m23 = transform.m23; m24 = transform.m24
            m31 = transform.m31; m32 = transform.m32; m33 = transform.m33; m34 = transform.m34
            m41 = transform.m41; m42 = transform.m42; m43 = transform.m43; m44 = transform.m44
        }

        var transform: CATransform3D {
            var result = CATransform3DIdentity
            result.m11 = m11; result.m12 = m12; result.m13 = m13; result.m14 = m14
            result.m21 = m21; result.m22 = m22; result.m23 = m23; result.m24 = m24
            result.m31 = m31; result.m32 = m32; result.m33 = m33; result.m34 = m34
            result.m41 = m41; result.m42 = m42; result.m43 = m43; result.m44 = m44
            return result
        }
    }
    // swiftlint:enable identifier_name

    private enum CodingKeys: String, CodingKey {
        case skewSublayerTransform
        case scrollContentOffset
        case scrollBoundsSize
        case imageContainerFrame
        case scrollViewTransform
    }

    package init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        skewSublayerTransform = try container.decode(Transform3DBox.self, forKey: .skewSublayerTransform).transform
        scrollContentOffset = try container.decode(CGPoint.self, forKey: .scrollContentOffset)
        scrollBoundsSize = try container.decode(CGSize.self, forKey: .scrollBoundsSize)
        imageContainerFrame = try container.decode(CGRect.self, forKey: .imageContainerFrame)
        scrollViewTransform = try container.decode(AffineTransformBox.self, forKey: .scrollViewTransform).transform
    }

    package func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Transform3DBox(skewSublayerTransform), forKey: .skewSublayerTransform)
        try container.encode(scrollContentOffset, forKey: .scrollContentOffset)
        try container.encode(scrollBoundsSize, forKey: .scrollBoundsSize)
        try container.encode(imageContainerFrame, forKey: .imageContainerFrame)
        try container.encode(AffineTransformBox(scrollViewTransform), forKey: .scrollViewTransform)
    }
}
