//
//  CGImage+Crop.swift
//  MantisCore
//
//  The crop pipeline, expressed on CGImage + CGImagePropertyOrientation so it
//  builds without UIKit. Mantis wraps it for UIImage.
//

import CoreGraphics
import CoreImage
import QuartzCore

/// A shared `CIContext` for perspective cropping.
///
/// `CIContext` is expensive to create (it can allocate GPU/Metal resources),
/// so creating a new instance per crop adds noticeable overhead. `CIContext` is
/// thread-safe, so a single shared instance can be reused across crops.
private enum SharedCIContext {
    static let context = CIContext(options: [.useSoftwareRenderer: false])
}

extension CGImagePropertyOrientation {
    var swapsWidthAndHeight: Bool {
        switch self {
        case .left, .leftMirrored, .right, .rightMirrored:
            return true
        default:
            return false
        }
    }

    /// The transform that draws the stored pixels upright onto a canvas of
    /// `size` (the oriented size).
    func uprightTransform(for size: CGSize) -> CGAffineTransform {
        let width = size.width
        let height = size.height

        var transform = CGAffineTransform.identity

        switch self {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: width, y: height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.rotated(by: 0.5 * .pi)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.rotated(by: -0.5 * .pi)
        case .up, .upMirrored:
            break
        }

        switch self {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }

        return transform
    }
}

extension CropInfo {
    /// Pixel size of the crop result for a source whose upright pixel size is
    /// `imageSize`, or `.zero` when the crop info is degenerate.
    package func outputImageSize(forImageSize imageSize: CGSize) -> CGSize {
        let zoomScaleX = abs(scaleX)
        let zoomScaleY = abs(scaleY)

        guard imageViewSize.width > 0, imageViewSize.height > 0,
              zoomScaleX > 0, zoomScaleY > 0 else {
            return .zero
        }

        let expectedWidth = round((imageSize.width / imageViewSize.width * cropSize.width) / zoomScaleX)
        let expectedHeight = round((imageSize.height / imageViewSize.height * cropSize.height) / zoomScaleY)

        guard expectedWidth.isFinite, expectedHeight.isFinite,
              expectedWidth > 0, expectedHeight > 0 else {
            return .zero
        }
        return CGSize(width: expectedWidth, height: expectedHeight)
    }
}

extension CGImage {
    package func orientedSize(_ orientation: CGImagePropertyOrientation) -> CGSize {
        orientation.swapsWidthAndHeight
        ? CGSize(width: height, height: width)
        : CGSize(width: width, height: height)
    }

    /// Returns the image redrawn upright, i.e. with `orientation` baked into the pixels.
    package func withFixedOrientation(_ orientation: CGImagePropertyOrientation) -> CGImage? {
        if orientation == .up {
            return self
        }

        guard let colorSpace else {
            return nil
        }

        let size = orientedSize(orientation)

        var context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )

        if context == nil {
            context = createBackupCGContext(size: size, bitmapBytesPerRow: 0, colorSpaceRef: colorSpace)
        }

        guard let context else {
            return nil
        }

        context.concatenate(orientation.uprightTransform(for: size))

        if orientation.swapsWidthAndHeight {
            context.draw(self, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        } else {
            context.draw(self, in: CGRect(origin: .zero, size: size))
        }

        return context.makeImage()
    }

    /// Crops through a full-size CGContext: bakes the orientation in, then applies
    /// the crop transform (or, with skew, the perspective extraction).
    package func crop(by cropInfo: CropInfo, orientation: CGImagePropertyOrientation) -> CGImage? {
        guard let fixedOrientationImage = withFixedOrientation(orientation) else {
            return nil
        }

        let hasSkew = cropInfo.horizontalSkewDegrees != 0 || cropInfo.verticalSkewDegrees != 0

        if hasSkew {
            // When skew is applied, use CIPerspectiveCorrection to extract the correct
            // quadrilateral from the source image, matching the preview's perspective warp.
            return cropWithPerspective(CIImage(cgImage: fixedOrientationImage),
                                       uprightSize: fixedOrientationImage.orientedSize(.up),
                                       cropInfo: cropInfo)
        }

        var transform = CGAffineTransform.identity
        transform.transformed(by: cropInfo)

        let outputSize = cropInfo.outputImageSize(forImageSize: fixedOrientationImage.orientedSize(.up))

        do {
            return try fixedOrientationImage.transformedImage(transform,
                                                              outputSize: outputSize,
                                                              cropSize: cropInfo.cropSize,
                                                              imageViewSize: cropInfo.imageViewSize)
        } catch {
            print("*** Failed to get transfromed image ***")

            if let error = error as? ImageProcessError {
                print("Failed reason: \(error)")
            }

            return nil
        }
    }

    // MARK: - Large Image Support

    /// Returns true when the image's total pixel count exceeds `maxPixelCount`.
    /// A `maxPixelCount` of 0 (or less) disables the check.
    package func exceedsPixelCount(_ maxPixelCount: Int) -> Bool {
        guard maxPixelCount > 0 else { return false }
        return width * height > maxPixelCount
    }

    /// Memory-efficient crop using CIImage lazy pipeline.
    /// Uses CIImage.oriented() for lazy EXIF fix and CIPerspectiveCorrection for extraction.
    /// Handles both standard (translate/rotate/scale/flip) and perspective (skew) crops uniformly.
    /// CIImage only decodes the source pixels needed for the output region via GPU tiling.
    package func cropWithCIImage(by cropInfo: CropInfo, orientation: CGImagePropertyOrientation) -> CGImage? {
        // Lazy orientation fix — no full-size CGContext allocation
        let ciImage = CIImage(cgImage: self).oriented(orientation)
        return cropWithPerspective(ciImage, uprightSize: ciImage.extent.size, cropInfo: cropInfo)
    }

    /// Crops `ciImage` (already upright, `uprightSize` pixels) with perspective skew
    /// applied, matching the preview rendering.
    ///
    /// The preview rendering pipeline:
    /// 1. Image is in imageContainer (inside scroll view content)
    /// 2. sublayerTransform (3D perspective) is applied around scroll view center
    /// 3. Scroll view has 2D transform (rotation + flip) around its center
    /// 4. Crop box selects a rectangle from the screen-space result
    ///
    /// To find which source image pixels correspond to the crop box:
    /// 1. Express crop box corners in screen space relative to scroll view center
    /// 2. Apply inverse 2D transform → content-space coordinates relative to anchor
    /// 3. Apply inverse perspective projection → un-warped content coordinates
    /// 4. Convert to image pixel coordinates
    /// 5. Use CIPerspectiveCorrection to extract that quad
    private func cropWithPerspective(_ ciImage: CIImage, uprightSize: CGSize, cropInfo: CropInfo) -> CGImage? {
        let imageViewSize = cropInfo.imageViewSize
        let cropSize = cropInfo.cropSize

        let outputSize = cropInfo.outputImageSize(forImageSize: uprightSize)
        guard outputSize != .zero else { return nil }

        guard let reconstruction = cropInfo.viewReconstruction else { return nil }
        let scrollBoundsSize = reconstruction.scrollBoundsSize
        let scrollContentOffset = reconstruction.scrollContentOffset
        let imgContainerFrame = reconstruction.imageContainerFrame
        let sublayerTransform = reconstruction.skewSublayerTransform

        guard imgContainerFrame.size.width > 0, imgContainerFrame.size.height > 0,
              imgContainerFrame.size.width.isFinite, imgContainerFrame.size.height.isFinite,
              imgContainerFrame.origin.x.isFinite, imgContainerFrame.origin.y.isFinite else { return nil }

        // sublayerTransform anchor in content coordinates
        let anchorX = scrollContentOffset.x + scrollBoundsSize.width / 2
        let anchorY = scrollContentOffset.y + scrollBoundsSize.height / 2

        // Step 1: Crop box corners in screen space, relative to scroll view center.
        let halfCropW = cropSize.width / 2
        let halfCropH = cropSize.height / 2
        let screenCorners = [
            CGPoint(x: -halfCropW, y: -halfCropH), // TL
            CGPoint(x: halfCropW, y: -halfCropH), // TR
            CGPoint(x: halfCropW, y: halfCropH), // BR
            CGPoint(x: -halfCropW, y: halfCropH)  // BL
        ]

        // Step 2: Apply inverse 2D transform to go from screen space to content space.
        //
        // The scroll view's actual CGAffineTransform (rotation + flip) is used
        // directly instead of reconstructing from decomposed rotation / scale
        // values. The flip() method builds the transform via
        //   R(rot) · S(flip) · R(extra)
        // which does not decompose cleanly into a single rotation + scale pair.
        //
        // `inverted()` returns a singular transform unchanged, which would map the
        // crop box onto the wrong region. A decoded CropInfo can carry one, so refuse it.
        let scrollViewTransform = reconstruction.scrollViewTransform
        let determinant = scrollViewTransform.a * scrollViewTransform.d - scrollViewTransform.b * scrollViewTransform.c
        guard determinant.isFinite, abs(determinant) > 1e-10 else { return nil }
        let inverseTransform = scrollViewTransform.inverted()
        let contentCorners = screenCorners.map { $0.applying(inverseTransform) }

        // Step 3: Inverse-project through sublayerTransform to find un-warped content positions
        let sourceContentDisplacements = contentCorners.map {
            Self.inverseProjectDisplacement($0, through: sublayerTransform)
        }

        // Step 4: Convert from content-space displacements (from anchor) to image pixel coordinates
        let pixelScaleX = uprightSize.width / imageViewSize.width
        let pixelScaleY = uprightSize.height / imageViewSize.height

        let sourcePixelPoints = sourceContentDisplacements.map { disp -> CGPoint in
            // Content coordinates (absolute)
            let contentX = disp.x + anchorX
            let contentY = disp.y + anchorY

            // Image container local coordinates
            let localX = contentX - imgContainerFrame.origin.x
            let localY = contentY - imgContainerFrame.origin.y

            // Scale from container frame size to imageView bounds size
            let boundsX = localX / imgContainerFrame.width * imageViewSize.width
            let boundsY = localY / imgContainerFrame.height * imageViewSize.height

            // To pixel coordinates
            return CGPoint(x: boundsX * pixelScaleX, y: boundsY * pixelScaleY)
        }

        // Step 5: Use CIPerspectiveCorrection to extract the quadrilateral.
        // CIPerspectiveCorrection uses Core Image coordinates (origin at bottom-left),
        // so flip Y from pixel coordinates (origin at top-left).
        let pts = sourcePixelPoints.map { CGPoint(x: $0.x, y: uprightSize.height - $0.y) }

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: pts[0].x, y: pts[0].y), forKey: "inputTopLeft")
        filter.setValue(CIVector(x: pts[1].x, y: pts[1].y), forKey: "inputTopRight")
        filter.setValue(CIVector(x: pts[2].x, y: pts[2].y), forKey: "inputBottomRight")
        filter.setValue(CIVector(x: pts[3].x, y: pts[3].y), forKey: "inputBottomLeft")

        guard let correctedOutput = filter.outputImage,
              correctedOutput.extent.width > 0,
              correctedOutput.extent.height > 0 else { return nil }

        // Render at desired output size
        let renderScaleX = outputSize.width / correctedOutput.extent.width
        let renderScaleY = outputSize.height / correctedOutput.extent.height
        guard renderScaleX.isFinite, renderScaleY.isFinite,
              renderScaleX > 0, renderScaleY > 0 else { return nil }
        let scaledImage = correctedOutput.transformed(by: CGAffineTransform(scaleX: renderScaleX, y: renderScaleY))

        return SharedCIContext.context.createCGImage(scaledImage, from: scaledImage.extent)
    }

    /// Inverse-projects a 2D point through a CATransform3D.
    ///
    /// Given the forward projection `projected = project(source, T)`, this finds `source`
    /// given `projected` and `T`.
    ///
    /// For a point on the z=0 plane, the forward projection is:
    ///   px = (x * m11 + y * m21 + m41) / w
    ///   py = (x * m12 + y * m22 + m42) / w
    ///   w  = (x * m14 + y * m24 + m44)
    ///
    /// Given (px, py), we solve for (x, y):
    ///   x * m11 + y * m21 + m41 = px * (x * m14 + y * m24 + m44)
    ///   x * m12 + y * m22 + m42 = py * (x * m14 + y * m24 + m44)
    ///
    /// Rearranging:
    ///   x * (m11 - px*m14) + y * (m21 - px*m24) = px*m44 - m41
    ///   x * (m12 - py*m14) + y * (m22 - py*m24) = py*m44 - m42
    private static func inverseProjectDisplacement(_ projected: CGPoint, through transform: CATransform3D) -> CGPoint {
        let projX = projected.x
        let projY = projected.y

        let a11 = transform.m11 - projX * transform.m14
        let a12 = transform.m21 - projX * transform.m24
        let rhs1 = projX * transform.m44 - transform.m41

        let a21 = transform.m12 - projY * transform.m14
        let a22 = transform.m22 - projY * transform.m24
        let rhs2 = projY * transform.m44 - transform.m42

        let det = a11 * a22 - a12 * a21
        guard abs(det) > 1e-10 else { return projected }

        let srcX = (rhs1 * a22 - rhs2 * a12) / det
        let srcY = (a11 * rhs2 - a21 * rhs1) / det

        return CGPoint(x: srcX, y: srcY)
    }
}
