//
//  MantisCore.swift
//  MantisCore
//
//  The UIKit-free crop engine behind Mantis. It builds on iOS, Mac Catalyst,
//  macOS and visionOS; Mantis re-exports it, so iOS code that imports Mantis
//  sees these APIs too.
//

import CoreGraphics
import ImageIO

/// Crops an image offline (without any crop UI) using a previously obtained `CropInfo`.
///
/// A `CropInfo` produced by Mantis on one device can be encoded, sent elsewhere
/// (for example to a Mac) and replayed here against the full-resolution original.
///
/// - Parameters:
///   - orientation: the EXIF orientation of `image` (for example the value of
///     `kCGImagePropertyOrientation` from `CGImageSource`). The result is always upright.
///   - maxImagePixelCount: when greater than 0 and the image's pixel count exceeds
///     it, the memory-efficient CIImage pipeline is used instead of the CGContext
///     pipeline. Pass the same value used in `CropViewConfig.maxImagePixelCount`.
///     Defaults to 0 (disabled).
public func crop(_ image: CGImage,
                 orientation: CGImagePropertyOrientation = .up,
                 by cropInfo: CropInfo,
                 maxImagePixelCount: Int = 0) -> CGImage? {
    if image.exceedsPixelCount(maxImagePixelCount) {
        return image.cropWithCIImage(by: cropInfo, orientation: orientation)
    }
    return image.crop(by: cropInfo, orientation: orientation)
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

/// AppKit convenience over `crop(_:orientation:by:maxImagePixelCount:)`.
///
/// `NSImage` applies the EXIF orientation when it loads an image, so its
/// `CGImage` is already upright and is cropped as `.up`.
public func crop(_ image: NSImage, by cropInfo: CropInfo, maxImagePixelCount: Int = 0) -> NSImage? {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
          let cropped = crop(cgImage, by: cropInfo, maxImagePixelCount: maxImagePixelCount) else {
        return nil
    }
    return NSImage(cgImage: cropped, size: .zero)
}
#endif
