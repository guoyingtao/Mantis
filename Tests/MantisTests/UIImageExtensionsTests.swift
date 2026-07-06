//
//  UIImageExtensionsTests.swift
//  MantisTests
//
//  Covers the pure image-geometry helpers on UIImage: EXIF orientation
//  mapping, orientation-baking, output-size math, and the perspective crop
//  pipeline. The perspective test drives crop(by:) with a skew flag but an
//  identity warp, so its result must match the trusted legacy (non-skew) crop
//  pixel-for-pixel — exercising the 100+ line cropWithPerspective coordinate
//  math end to end.
//

import XCTest
@testable import Mantis

final class UIImageExtensionsTests: XCTestCase {

    // MARK: - Helpers

    /// Builds a bitmap of exact pixel dimensions (scale 1) so `size` equals pixels.
    private func makeCGImage(width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(UIColor.gray.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    private func makeImage(width: Int, height: Int,
                           orientation: UIImage.Orientation = .up) -> UIImage {
        UIImage(cgImage: makeCGImage(width: width, height: height), scale: 1, orientation: orientation)
    }

    /// Draws a 4-quadrant colored pattern so any coordinate-space mistake
    /// changes the sampled colors. (Mirrors the helper in CICropEquivalenceTests.)
    private func makePatternImage(width: Int, height: Int) -> UIImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let halfW = CGFloat(width) / 2
        let halfH = CGFloat(height) / 2
        context.setFillColor(UIColor.red.cgColor)    // bottom-left
        context.fill(CGRect(x: 0, y: 0, width: halfW, height: halfH))
        context.setFillColor(UIColor.green.cgColor)  // bottom-right
        context.fill(CGRect(x: halfW, y: 0, width: halfW, height: halfH))
        context.setFillColor(UIColor.blue.cgColor)   // top-left
        context.fill(CGRect(x: 0, y: halfH, width: halfW, height: halfH))
        context.setFillColor(UIColor.yellow.cgColor) // top-right
        context.fill(CGRect(x: halfW, y: halfH, width: halfW, height: halfH))
        return UIImage(cgImage: context.makeImage()!, scale: 1, orientation: .up)
    }

    private func pixel(of image: UIImage, atNormalized point: CGPoint) -> [CGFloat]? {
        guard let cgImage = image.cgImage else { return nil }
        let posX = Int(CGFloat(cgImage.width) * point.x)
        let posY = Int(CGFloat(cgImage.height) * point.y)
        var data = [UInt8](repeating: 0, count: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: &data, width: 1, height: 1,
                                      bitsPerComponent: 8, bytesPerRow: 4,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(cgImage, in: CGRect(x: -CGFloat(posX),
                                         y: CGFloat(posY) - CGFloat(cgImage.height) + 1,
                                         width: CGFloat(cgImage.width),
                                         height: CGFloat(cgImage.height)))
        return data.map { CGFloat($0) / 255.0 }
    }

    // MARK: - exifOrientation

    func testExifOrientationMapsAllCases() {
        let expected: [UIImage.Orientation: Int32] = [
            .up: 1, .upMirrored: 2, .down: 3, .downMirrored: 4,
            .leftMirrored: 5, .right: 6, .rightMirrored: 7, .left: 8
        ]
        for (orientation, exif) in expected {
            let image = makeImage(width: 10, height: 10, orientation: orientation)
            XCTAssertEqual(image.exifOrientation, exif, "orientation \(orientation.rawValue)")
        }
    }

    // MARK: - isHorizontal / horizontalToVerticalRatio

    func testIsHorizontal() {
        XCTAssertTrue(makeImage(width: 40, height: 20).isHorizontal())
        XCTAssertFalse(makeImage(width: 20, height: 40).isHorizontal())
        XCTAssertFalse(makeImage(width: 30, height: 30).isHorizontal())
    }

    func testHorizontalToVerticalRatio() {
        XCTAssertEqual(makeImage(width: 40, height: 20).horizontalToVerticalRatio(), 2.0, accuracy: 1e-9)
        XCTAssertEqual(makeImage(width: 20, height: 40).horizontalToVerticalRatio(), 0.5, accuracy: 1e-9)
    }

    // MARK: - exceedsPixelCount

    func testExceedsPixelCount() {
        let image = makeImage(width: 100, height: 100) // 10,000 px at scale 1
        XCTAssertFalse(image.exceedsPixelCount(0), "0 disables the check")
        XCTAssertFalse(image.exceedsPixelCount(-1), "negative disables the check")
        XCTAssertFalse(image.exceedsPixelCount(10_000), "boundary is strict >, so equal does not exceed")
        XCTAssertFalse(image.exceedsPixelCount(20_000))
        XCTAssertTrue(image.exceedsPixelCount(5_000))
    }

    // MARK: - getOutputCropImageSize

    private func cropInfo(imageViewSize: CGSize, cropSize: CGSize, zoom: CGFloat) -> CropInfo {
        CropInfo(translation: .zero, rotation: 0, scaleX: zoom, scaleY: zoom,
                 cropSize: cropSize, imageViewSize: imageViewSize,
                 cropRegion: CropRegion(topLeft: .zero, topRight: .zero, bottomLeft: .zero, bottomRight: .zero))
    }

    func testGetOutputCropImageSize() {
        let image = makeImage(width: 1000, height: 800)
        let size = image.getOutputCropImageSize(by: cropInfo(imageViewSize: CGSize(width: 500, height: 400),
                                                             cropSize: CGSize(width: 200, height: 160),
                                                             zoom: 1))
        // 1000/500 * 200 = 400,  800/400 * 160 = 320
        XCTAssertEqual(size, CGSize(width: 400, height: 320))
    }

    func testGetOutputCropImageSizeWithZoom() {
        let image = makeImage(width: 1000, height: 800)
        let size = image.getOutputCropImageSize(by: cropInfo(imageViewSize: CGSize(width: 500, height: 400),
                                                             cropSize: CGSize(width: 200, height: 160),
                                                             zoom: 2))
        XCTAssertEqual(size, CGSize(width: 200, height: 160))
    }

    func testGetOutputCropImageSizeGuardsAgainstDegenerateInput() {
        let image = makeImage(width: 1000, height: 800)
        XCTAssertEqual(image.getOutputCropImageSize(by: cropInfo(imageViewSize: .zero,
                                                                cropSize: CGSize(width: 200, height: 160),
                                                                zoom: 1)), .zero)
        XCTAssertEqual(image.getOutputCropImageSize(by: cropInfo(imageViewSize: CGSize(width: 500, height: 400),
                                                                cropSize: CGSize(width: 200, height: 160),
                                                                zoom: 0)), .zero)
    }

    // MARK: - cgImageWithFixedOrientation

    func testFixedOrientationUpReturnsSameDimensions() {
        let image = makeImage(width: 40, height: 20, orientation: .up)
        let fixed = image.cgImageWithFixedOrientation()
        XCTAssertNotNil(fixed)
        XCTAssertEqual(fixed?.width, 40)
        XCTAssertEqual(fixed?.height, 20)
    }

    func testFixedOrientationKeepsDimensionsForUpAndDownFamilies() {
        // .up / .down families do not swap width and height.
        for orientation in [UIImage.Orientation.up, .upMirrored, .down, .downMirrored] {
            let fixed = makeImage(width: 40, height: 20, orientation: orientation).cgImageWithFixedOrientation()
            XCTAssertEqual(fixed?.width, 40, "orientation \(orientation.rawValue)")
            XCTAssertEqual(fixed?.height, 20, "orientation \(orientation.rawValue)")
        }
    }

    func testFixedOrientationSwapsDimensionsForLeftAndRightFamilies() {
        // .left / .right families rotate 90°, so a 40x20 source becomes 20x40.
        for orientation in [UIImage.Orientation.left, .leftMirrored, .right, .rightMirrored] {
            let fixed = makeImage(width: 40, height: 20, orientation: orientation).cgImageWithFixedOrientation()
            XCTAssertEqual(fixed?.width, 20, "orientation \(orientation.rawValue)")
            XCTAssertEqual(fixed?.height, 40, "orientation \(orientation.rawValue)")
        }
    }

    // MARK: - cropWithPerspective (via crop(by:))

    /// Same centered-crop geometry used by CICropEquivalenceTests.
    private func makeCropInfo(viewSize: CGSize, cropSize: CGSize, zoom: CGFloat,
                              contentOffset: CGPoint, horizontalSkewDegrees: CGFloat) -> CropInfo {
        let containerCenter = CGPoint(x: viewSize.width * zoom / 2, y: viewSize.height * zoom / 2)
        let cropBoxCenter = CGPoint(x: contentOffset.x + cropSize.width / 2,
                                    y: contentOffset.y + cropSize.height / 2)
        var info = CropInfo(
            translation: CGPoint(x: containerCenter.x - cropBoxCenter.x, y: containerCenter.y - cropBoxCenter.y),
            rotation: 0,
            scaleX: zoom,
            scaleY: zoom,
            cropSize: cropSize,
            imageViewSize: viewSize,
            cropRegion: CropRegion(topLeft: .zero, topRight: .zero, bottomLeft: .zero, bottomRight: .zero),
            horizontalSkewDegrees: horizontalSkewDegrees,
            verticalSkewDegrees: 0
        )
        info.viewReconstruction = CropInfo.ViewReconstruction(
            skewSublayerTransform: CATransform3DIdentity, // identity => no actual warp
            scrollContentOffset: contentOffset,
            scrollBoundsSize: cropSize,
            imageContainerFrame: CGRect(origin: .zero,
                                        size: CGSize(width: viewSize.width * zoom, height: viewSize.height * zoom)),
            scrollViewTransform: .identity
        )
        return info
    }

    func testCropWithPerspectiveIdentityWarpMatchesLegacyCrop() {
        let image = makePatternImage(width: 1000, height: 800)
        let viewSize = CGSize(width: 500, height: 400)
        let cropSize = CGSize(width: 200, height: 160)
        let contentOffset = CGPoint(x: 150, y: 120)

        // Legacy affine path (no skew).
        let legacyInfo = makeCropInfo(viewSize: viewSize, cropSize: cropSize, zoom: 1,
                                      contentOffset: contentOffset, horizontalSkewDegrees: 0)
        // Perspective path: skew flag set (routes to cropWithPerspective) but the
        // sublayer transform is identity, so the extracted quad is the same rect.
        let perspectiveInfo = makeCropInfo(viewSize: viewSize, cropSize: cropSize, zoom: 1,
                                           contentOffset: contentOffset, horizontalSkewDegrees: 5)

        guard let legacy = image.crop(by: legacyInfo) else {
            XCTFail("legacy crop returned nil"); return
        }
        guard let perspective = image.crop(by: perspectiveInfo) else {
            XCTFail("perspective crop returned nil"); return
        }

        XCTAssertEqual(legacy.size.width, perspective.size.width, accuracy: 2.0)
        XCTAssertEqual(legacy.size.height, perspective.size.height, accuracy: 2.0)

        let samplePoints = [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25),
                            CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.75, y: 0.75),
                            CGPoint(x: 0.5, y: 0.5)]
        for point in samplePoints {
            guard let legacyPixel = pixel(of: legacy, atNormalized: point),
                  let perspectivePixel = pixel(of: perspective, atNormalized: point) else {
                XCTFail("could not sample pixel at \(point)"); continue
            }
            for channel in 0..<3 {
                XCTAssertEqual(legacyPixel[channel], perspectivePixel[channel], accuracy: 0.1,
                               "pixel mismatch at \(point) channel \(channel)")
            }
        }
    }

    func testCropWithPerspectiveReturnsNilForDegenerateInput() {
        let image = makePatternImage(width: 200, height: 160)
        var info = makeCropInfo(viewSize: CGSize(width: 100, height: 80),
                                cropSize: CGSize(width: 40, height: 32),
                                zoom: 1, contentOffset: CGPoint(x: 30, y: 24),
                                horizontalSkewDegrees: 5)
        info.imageViewSize = .zero
        XCTAssertNil(image.crop(by: info), "zero imageViewSize must not crash or return garbage")
    }
}
