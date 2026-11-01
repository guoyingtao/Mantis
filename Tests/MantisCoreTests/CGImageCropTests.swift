//
//  CGImageCropTests.swift
//  MantisCoreTests
//
//  Covers the UIKit-free crop pipeline on CGImage. These tests run on every
//  platform MantisCore supports, including macOS. Orientation handling is
//  checked against Core Image's own `oriented(_:)` as an independent reference.
//

import CoreImage
import ImageIO
import XCTest
@testable import MantisCore
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

final class CGImageCropTests: XCTestCase {

    // MARK: - Helpers

    private static let allOrientations: [CGImagePropertyOrientation] = [
        .up, .upMirrored, .down, .downMirrored, .leftMirrored, .right, .rightMirrored, .left
    ]

    /// Non-square, high-frequency pattern: any off-by-one, flip or orientation
    /// mistake changes many pixels.
    private func makePatternImage(width: Int = 240, height: Int = 160) -> CGImage {
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        for posY in 0..<height {
            for posX in 0..<width {
                let index = (posY * width + posX) * 4
                bytes[index] = UInt8(posX % 256)
                bytes[index + 1] = UInt8(posY % 256)
                bytes[index + 2] = UInt8(((posX / 7 + posY / 5) % 2) * 160 + (posX < width / 2 ? 0 : 60))
            }
        }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                       provider: CGDataProvider(data: Data(bytes) as CFData)!,
                       decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
    }

    private struct Pixels {
        var width: Int
        var height: Int
        var rgba: [UInt8]
    }

    private func pixels(_ image: CGImage) -> Pixels {
        var rgba = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = CGContext(data: &rgba, width: image.width, height: image.height, bitsPerComponent: 8,
                                bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return Pixels(width: image.width, height: image.height, rgba: rgba)
    }

    /// Asserts both images have the same size and every channel is within `tolerance`.
    private func assertSamePixels(_ lhs: CGImage?, _ rhs: CGImage?, tolerance: Int = 0, _ message: String,
                                  file: StaticString = #filePath, line: UInt = #line) {
        guard let lhs, let rhs else {
            XCTFail("nil image: \(message)", file: file, line: line); return
        }
        let left = pixels(lhs)
        let right = pixels(rhs)
        guard left.width == right.width, left.height == right.height else {
            XCTFail("size \(left.width)x\(left.height) vs \(right.width)x\(right.height): \(message)",
                    file: file, line: line)
            return
        }
        let maxDiff = zip(left.rgba, right.rgba).map { abs(Int($0) - Int($1)) }.max() ?? 0
        XCTAssertLessThanOrEqual(maxDiff, tolerance, message, file: file, line: line)
    }

    /// Core Image's rendering of `image` with `orientation` applied.
    private func coreImageUpright(_ image: CGImage, _ orientation: CGImagePropertyOrientation) -> CGImage? {
        let oriented = CIImage(cgImage: image).oriented(orientation)
        return CIContext().createCGImage(oriented, from: oriented.extent)
    }

    /// A crop of an upright image of `uprightSize` pixels shown at half size,
    /// with the crop box over its center, optionally zoomed, offset and skewed.
    private func makeCropInfo(uprightSize: CGSize,
                              zoom: CGFloat = 1,
                              offset: CGPoint = .zero,
                              horizontalSkewDegrees: CGFloat = 0,
                              skewTransform: CATransform3D = CATransform3DIdentity,
                              withViewReconstruction: Bool = true) -> CropInfo {
        let viewSize = CGSize(width: uprightSize.width / 2, height: uprightSize.height / 2)
        let cropSize = CGSize(width: viewSize.width / 2, height: viewSize.height / 2)
        let containerSize = CGSize(width: viewSize.width * zoom, height: viewSize.height * zoom)
        let contentOffset = CGPoint(x: (containerSize.width - cropSize.width) / 2 - offset.x,
                                    y: (containerSize.height - cropSize.height) / 2 - offset.y)
        var info = CropInfo(translation: offset,
                            rotation: 0,
                            scaleX: zoom,
                            scaleY: zoom,
                            cropSize: cropSize,
                            imageViewSize: viewSize,
                            cropRegion: CropRegion(topLeft: .zero, topRight: .zero, bottomLeft: .zero, bottomRight: .zero),
                            horizontalSkewDegrees: horizontalSkewDegrees)
        if withViewReconstruction {
            info.viewReconstruction = CropInfo.ViewReconstruction(
                skewSublayerTransform: skewTransform,
                scrollContentOffset: contentOffset,
                scrollBoundsSize: cropSize,
                imageContainerFrame: CGRect(origin: .zero, size: containerSize),
                scrollViewTransform: .identity)
        }
        return info
    }

    // MARK: - Orientation

    func testFixedOrientationMatchesCoreImageForAllOrientations() {
        let image = makePatternImage()
        for orientation in Self.allOrientations {
            assertSamePixels(image.withFixedOrientation(orientation), coreImageUpright(image, orientation),
                             "orientation \(orientation.rawValue)")
        }
    }

    func testOrientedSizeSwapsOnlyForQuarterTurns() {
        let image = makePatternImage(width: 40, height: 20)
        for orientation in Self.allOrientations {
            let expected = orientation.swapsWidthAndHeight ? CGSize(width: 20, height: 40) : CGSize(width: 40, height: 20)
            XCTAssertEqual(image.orientedSize(orientation), expected, "orientation \(orientation.rawValue)")
        }
    }

    func testCropOfOrientedImageMatchesCropOfUprightImage() {
        let image = makePatternImage()
        for orientation in Self.allOrientations {
            guard let upright = coreImageUpright(image, orientation) else {
                XCTFail("reference render failed"); continue
            }
            let info = makeCropInfo(uprightSize: image.orientedSize(orientation), zoom: 1.5, offset: CGPoint(x: 6, y: -4))
            assertSamePixels(crop(image, orientation: orientation, by: info),
                             crop(upright, by: info),
                             "orientation \(orientation.rawValue)")
        }
    }

    // MARK: - Pipelines

    func testCIPipelineMatchesCGPipeline() {
        let image = makePatternImage()
        for orientation in [CGImagePropertyOrientation.up, .right, .downMirrored] {
            let info = makeCropInfo(uprightSize: image.orientedSize(orientation), zoom: 2, offset: CGPoint(x: 10, y: 8))
            // Core Image resamples slightly differently at the crop edges.
            assertSamePixels(image.crop(by: info, orientation: orientation),
                             image.cropWithCIImage(by: info, orientation: orientation),
                             tolerance: 8,
                             "orientation \(orientation.rawValue)")
        }
    }

    func testIdentitySkewMatchesPlainCrop() {
        // A skew flag routes the crop through the perspective path; with an
        // identity warp it must extract the same rectangle as the affine path.
        let image = makePatternImage()
        let size = image.orientedSize(.up)
        let plain = makeCropInfo(uprightSize: size, offset: CGPoint(x: 12, y: 6))
        let skewed = makeCropInfo(uprightSize: size, offset: CGPoint(x: 12, y: 6), horizontalSkewDegrees: 5)
        assertSamePixels(crop(image, by: plain), crop(image, by: skewed), tolerance: 8, "identity skew")
    }

    func testRealSkewChangesTheResult() {
        let image = makePatternImage()
        var warp = CATransform3DIdentity
        warp.m34 = -1.0 / 500.0
        warp = CATransform3DRotate(warp, 15 * .pi / 180, 0, 1, 0)
        let info = makeCropInfo(uprightSize: image.orientedSize(.up), horizontalSkewDegrees: 15, skewTransform: warp)
        let plain = makeCropInfo(uprightSize: image.orientedSize(.up))

        let skewed = crop(image, by: info).map(pixels)
        let unskewed = crop(image, by: plain).map(pixels)
        XCTAssertNotNil(skewed)
        XCTAssertNotEqual(skewed?.rgba, unskewed?.rgba)
    }

    func testPublicCropRoutesByPixelCount() {
        let image = makePatternImage()
        let info = makeCropInfo(uprightSize: image.orientedSize(.up), zoom: 2)
        assertSamePixels(crop(image, by: info), image.crop(by: info, orientation: .up), "below the threshold")
        assertSamePixels(crop(image, by: info, maxImagePixelCount: 100),
                         image.cropWithCIImage(by: info, orientation: .up),
                         "above the threshold")
    }

    func testExceedsPixelCount() {
        let image = makePatternImage(width: 100, height: 100)
        XCTAssertFalse(image.exceedsPixelCount(0), "0 disables the check")
        XCTAssertFalse(image.exceedsPixelCount(-1), "negative disables the check")
        XCTAssertFalse(image.exceedsPixelCount(10_000), "boundary is strict >, so equal does not exceed")
        XCTAssertTrue(image.exceedsPixelCount(5_000))
    }

    // MARK: - Output size and degenerate input

    func testOutputImageSize() {
        let info = makeCropInfo(uprightSize: CGSize(width: 1000, height: 800))
        // view 500x400, crop 250x200 at zoom 1: 1000/500 * 250 = 500, 800/400 * 200 = 400
        XCTAssertEqual(info.outputImageSize(forImageSize: CGSize(width: 1000, height: 800)), CGSize(width: 500, height: 400))

        let zoomed = makeCropInfo(uprightSize: CGSize(width: 1000, height: 800), zoom: 2)
        XCTAssertEqual(zoomed.outputImageSize(forImageSize: CGSize(width: 1000, height: 800)), CGSize(width: 250, height: 200))
    }

    func testDegenerateCropInfoReturnsNil() {
        let image = makePatternImage()
        var info = makeCropInfo(uprightSize: image.orientedSize(.up))

        info.imageViewSize = .zero
        XCTAssertEqual(info.outputImageSize(forImageSize: CGSize(width: 240, height: 160)), .zero)
        XCTAssertNil(crop(image, by: info))
        XCTAssertNil(crop(image, by: info, maxImagePixelCount: 100))

        info = makeCropInfo(uprightSize: image.orientedSize(.up))
        info.scaleX = 0
        XCTAssertNil(crop(image, by: info))
    }

    func testPerspectiveAndCIPathsNeedViewReconstruction() {
        // A hand-built CropInfo has no captured view state: the paths that
        // invert the on-screen transform must refuse rather than guess.
        let image = makePatternImage()
        let size = image.orientedSize(.up)
        let skewed = makeCropInfo(uprightSize: size, horizontalSkewDegrees: 5, withViewReconstruction: false)
        XCTAssertNil(crop(image, by: skewed))

        let plain = makeCropInfo(uprightSize: size, withViewReconstruction: false)
        XCTAssertNotNil(crop(image, by: plain), "the affine path does not need view state")
        XCTAssertNil(crop(image, by: plain, maxImagePixelCount: 100))
    }

    func testCropInfoCodableRoundTripKeepsViewReconstruction() throws {
        let image = makePatternImage()
        let info = makeCropInfo(uprightSize: image.orientedSize(.up), zoom: 1.5, offset: CGPoint(x: 5, y: 3))
        let decoded = try JSONDecoder().decode(CropInfo.self, from: JSONEncoder().encode(info))
        XCTAssertNotNil(decoded.viewReconstruction)
        assertSamePixels(crop(image, by: info, maxImagePixelCount: 100),
                         crop(image, by: decoded, maxImagePixelCount: 100),
                         "decoded CropInfo")
    }

    // MARK: - AppKit

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    func testNSImageCropMatchesCGImageCrop() throws {
        let cgImage = makePatternImage()
        let info = makeCropInfo(uprightSize: cgImage.orientedSize(.up), zoom: 1.5)
        let cropped = try XCTUnwrap(crop(NSImage(cgImage: cgImage, size: .zero), by: info))
        assertSamePixels(cropped.cgImage(forProposedRect: nil, context: nil, hints: nil), crop(cgImage, by: info),
                         "NSImage convenience")
    }

    func testNSImageLoadedFromEXIFTaggedDataIsUpright() throws {
        // The NSImage overload crops as `.up`; that is only right because AppKit
        // applies the EXIF orientation on load. Guard that assumption.
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, makePatternImage(width: 40, height: 20),
                                   [kCGImagePropertyOrientation: CGImagePropertyOrientation.right.rawValue] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))

        let image = try XCTUnwrap(NSImage(data: data as Data))
        let cgImage = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        XCTAssertEqual(cgImage.width, 20)
        XCTAssertEqual(cgImage.height, 40)
    }
    #endif
}
