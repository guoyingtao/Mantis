//
//  CICropEquivalenceTests.swift
//  MantisTests
//
//  Verifies that the new large-image CI crop pipeline (cropWithCIImage)
//  produces the same result as the legacy crop pipeline (crop(by:)).
//

import XCTest
@testable import Mantis

final class CICropEquivalenceTests: XCTestCase {

    /// Draws a 4-quadrant colored pattern so that any coordinate-space mistake
    /// (Y flip, mirroring, wrong quadrant) changes sampled colors.
    private func makePatternImage(width: Int, height: Int, orientation: UIImage.Orientation = .up) -> UIImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let halfW = CGFloat(width) / 2
        let halfH = CGFloat(height) / 2
        // CGContext origin is bottom-left
        context.setFillColor(UIColor.red.cgColor)      // bottom-left
        context.fill(CGRect(x: 0, y: 0, width: halfW, height: halfH))
        context.setFillColor(UIColor.green.cgColor)    // bottom-right
        context.fill(CGRect(x: halfW, y: 0, width: halfW, height: halfH))
        context.setFillColor(UIColor.blue.cgColor)     // top-left
        context.fill(CGRect(x: 0, y: halfH, width: halfW, height: halfH))
        context.setFillColor(UIColor.yellow.cgColor)   // top-right
        context.fill(CGRect(x: halfW, y: halfH, width: halfW, height: halfH))
        return UIImage(cgImage: context.makeImage()!, scale: 1, orientation: orientation)
    }

    /// Reads the RGBA pixel at a normalized position (0-1) of the image.
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
        context.draw(cgImage, in: CGRect(x: -CGFloat(posX), y: CGFloat(posY) - CGFloat(cgImage.height) + 1, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
        return data.map { CGFloat($0) / 255.0 }
    }

    private func makeCropInfo(imageSize: CGSize,
                              viewSize: CGSize,
                              cropSize: CGSize,
                              zoom: CGFloat = 1,
                              contentOffset: CGPoint) -> CropInfo {
        // translation = image container center - crop box center (both in content coords)
        let containerCenter = CGPoint(x: viewSize.width * zoom / 2, y: viewSize.height * zoom / 2)
        let cropBoxCenter = CGPoint(x: contentOffset.x + cropSize.width / 2, y: contentOffset.y + cropSize.height / 2)
        return CropInfo(
            translation: CGPoint(x: containerCenter.x - cropBoxCenter.x, y: containerCenter.y - cropBoxCenter.y),
            rotation: 0,
            scaleX: zoom,
            scaleY: zoom,
            cropSize: cropSize,
            imageViewSize: viewSize,
            cropRegion: CropRegion(topLeft: .zero, topRight: .zero, bottomLeft: .zero, bottomRight: .zero),
            horizontalSkewDegrees: 0,
            verticalSkewDegrees: 0,
            skewSublayerTransform: CATransform3DIdentity,
            scrollContentOffset: contentOffset,
            scrollBoundsSize: cropSize,
            imageContainerFrame: CGRect(origin: .zero, size: CGSize(width: viewSize.width * zoom, height: viewSize.height * zoom)),
            scrollViewTransform: .identity
        )
    }

    private func assertSameCrop(_ image: UIImage, _ cropInfo: CropInfo,
                                file: StaticString = #filePath, line: UInt = #line) {
        guard let legacy = image.crop(by: cropInfo) else {
            XCTFail("legacy crop returned nil", file: file, line: line); return
        }
        guard let ciCrop = image.cropWithCIImage(by: cropInfo) else {
            XCTFail("CI crop returned nil", file: file, line: line); return
        }

        XCTAssertEqual(legacy.size.width, ciCrop.size.width, accuracy: 2.0,
                       "output width differs", file: file, line: line)
        XCTAssertEqual(legacy.size.height, ciCrop.size.height, accuracy: 2.0,
                       "output height differs", file: file, line: line)

        // Sample the four quadrant centers plus the center point.
        let samplePoints = [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25),
                            CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.75, y: 0.75),
                            CGPoint(x: 0.5, y: 0.5)]
        for point in samplePoints {
            guard let legacyPixel = pixel(of: legacy, atNormalized: point),
                  let ciPixel = pixel(of: ciCrop, atNormalized: point) else {
                XCTFail("could not sample pixel at \(point)", file: file, line: line); continue
            }
            for channel in 0..<3 {
                XCTAssertEqual(legacyPixel[channel], ciPixel[channel], accuracy: 0.1,
                               "pixel mismatch at \(point) channel \(channel): legacy \(legacyPixel) vs CI \(ciPixel)",
                               file: file, line: line)
            }
        }
    }

    func testCICropMatchesLegacyCropCentered() {
        let image = makePatternImage(width: 1000, height: 800)
        // Crop the center: crop box shows the middle of the image
        let cropInfo = makeCropInfo(imageSize: image.size,
                                    viewSize: CGSize(width: 500, height: 400),
                                    cropSize: CGSize(width: 200, height: 160),
                                    contentOffset: CGPoint(x: 150, y: 120))
        assertSameCrop(image, cropInfo)
    }

    func testCICropMatchesLegacyCropOffCenter() {
        let image = makePatternImage(width: 1000, height: 800)
        // Crop box over the top-left region (blue in UIKit space)
        let cropInfo = makeCropInfo(imageSize: image.size,
                                    viewSize: CGSize(width: 500, height: 400),
                                    cropSize: CGSize(width: 200, height: 160),
                                    contentOffset: CGPoint(x: 20, y: 10))
        assertSameCrop(image, cropInfo)
    }

    func testCICropMatchesLegacyCropZoomed() {
        let image = makePatternImage(width: 1000, height: 800)
        let cropInfo = makeCropInfo(imageSize: image.size,
                                    viewSize: CGSize(width: 500, height: 400),
                                    cropSize: CGSize(width: 200, height: 160),
                                    zoom: 2,
                                    contentOffset: CGPoint(x: 400, y: 320))
        assertSameCrop(image, cropInfo)
    }

    func testCICropReturnsNilForDegenerateCropInfo() {
        let image = makePatternImage(width: 100, height: 80)
        var cropInfo = makeCropInfo(imageSize: image.size,
                                    viewSize: CGSize(width: 50, height: 40),
                                    cropSize: CGSize(width: 20, height: 16),
                                    contentOffset: CGPoint(x: 15, y: 12))

        cropInfo.imageViewSize = .zero
        XCTAssertNil(image.cropWithCIImage(by: cropInfo), "zero imageViewSize must not crash or return garbage")

        cropInfo.imageViewSize = CGSize(width: 50, height: 40)
        cropInfo.scaleX = 0
        XCTAssertNil(image.cropWithCIImage(by: cropInfo), "zero zoom scale must not crash or return garbage")

        cropInfo.scaleX = 1
        cropInfo.imageContainerFrame = CGRect(x: CGFloat.nan, y: 0, width: 50, height: 40)
        XCTAssertNil(image.cropWithCIImage(by: cropInfo), "NaN container frame must not crash or return garbage")
    }

    func testDownsampledIfNeeded() {
        let image = makePatternImage(width: 400, height: 200)

        // Disabled or within limits: returns self unchanged
        XCTAssertEqual(image.downsampledIfNeeded(maxPixelCount: 0), image)
        XCTAssertEqual(image.downsampledIfNeeded(maxPixelCount: 400 * 200), image)

        // Above the limit: total pixels come down to <= maxPixelCount, ratio preserved
        let downsampled = image.downsampledIfNeeded(maxPixelCount: 20000)
        let pixelCount = Int(downsampled.size.width * downsampled.scale) * Int(downsampled.size.height * downsampled.scale)
        XCTAssertLessThanOrEqual(pixelCount, 20000)
        XCTAssertGreaterThan(pixelCount, 20000 / 2, "downsampling should not overshoot")
        XCTAssertEqual(downsampled.size.width / downsampled.size.height, 2.0, accuracy: 0.05)

        // Quadrant colors stay in place (no flip/mirror introduced)
        let topLeft = pixel(of: downsampled, atNormalized: CGPoint(x: 0.25, y: 0.25))!
        XCTAssertEqual(topLeft[2], 1.0, accuracy: 0.1, "top-left should stay blue")

        // EXIF orientation gets baked in: a .right-tagged 400x200 bitmap displays as 200x400
        let oriented = makePatternImage(width: 400, height: 200, orientation: .right)
        let orientedDownsampled = oriented.downsampledIfNeeded(maxPixelCount: 20000)
        XCTAssertLessThan(orientedDownsampled.size.width, orientedDownsampled.size.height,
                          "downsampled image should keep the oriented (portrait) aspect")
        XCTAssertEqual(orientedDownsampled.imageOrientation, .up)
    }

    func testCICropMatchesLegacyCropWithEXIFOrientation() {
        // Same pixels but tagged .right (camera portrait): both pipelines must
        // normalize orientation identically.
        let image = makePatternImage(width: 1000, height: 800, orientation: .right)
        // After orientation fix the display size is 800x1000
        let cropInfo = makeCropInfo(imageSize: CGSize(width: 800, height: 1000),
                                    viewSize: CGSize(width: 400, height: 500),
                                    cropSize: CGSize(width: 160, height: 200),
                                    contentOffset: CGPoint(x: 120, y: 150))
        assertSameCrop(image, cropInfo)
    }

    // MARK: - Public free functions

    func testMantisCropFreeFunctionRoutesByPixelCount() {
        let image = makePatternImage(width: 1000, height: 800)
        let cropInfo = makeCropInfo(imageSize: image.size,
                                    viewSize: CGSize(width: 500, height: 400),
                                    cropSize: CGSize(width: 200, height: 160),
                                    contentOffset: CGPoint(x: 150, y: 120))

        // Default (disabled) uses the legacy pipeline.
        guard let legacy = Mantis.crop(image: image, by: cropInfo) else {
            XCTFail("legacy crop returned nil"); return
        }
        // Above threshold routes through the CIImage pipeline with the same result.
        guard let large = Mantis.crop(image: image, by: cropInfo, maxImagePixelCount: 1000) else {
            XCTFail("large-image crop returned nil"); return
        }
        XCTAssertEqual(legacy.size.width, large.size.width, accuracy: 2.0)
        XCTAssertEqual(legacy.size.height, large.size.height, accuracy: 2.0)
        for point in [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.75)] {
            let legacyPixel = pixel(of: legacy, atNormalized: point)!
            let largePixel = pixel(of: large, atNormalized: point)!
            for channel in 0..<3 {
                XCTAssertEqual(legacyPixel[channel], largePixel[channel], accuracy: 0.1)
            }
        }
    }

    func testMantisDownsampleFreeFunction() {
        let image = makePatternImage(width: 400, height: 200)
        XCTAssertEqual(Mantis.downsample(image: image, maxPixelCount: 0), image)
        let down = Mantis.downsample(image: image, maxPixelCount: 20000)
        let pixelCount = Int(down.size.width * down.scale) * Int(down.size.height * down.scale)
        XCTAssertLessThanOrEqual(pixelCount, 20000)
    }
}
