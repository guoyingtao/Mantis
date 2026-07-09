//
//  CropInfoCodableTests.swift
//  MantisTests
//
//  Verifies that CropInfo round-trips through Codable so crop settings can be
//  persisted and restored across app sessions (see issue #536), including the
//  internal ViewReconstruction state needed for perspective / large-image crops.
//

import XCTest
@testable import Mantis

final class CropInfoCodableTests: XCTestCase {

    // MARK: - Fixtures

    /// A plain crop with no rotation, skew or captured view state.
    private func makeStandardCropInfo() -> CropInfo {
        CropInfo(
            translation: CGPoint(x: 12, y: -34),
            rotation: 0,
            scaleX: 1,
            scaleY: 1,
            cropSize: CGSize(width: 200, height: 160),
            imageViewSize: CGSize(width: 500, height: 400),
            cropRegion: CropRegion(topLeft: CGPoint(x: 10, y: 20),
                                   topRight: CGPoint(x: 210, y: 20),
                                   bottomLeft: CGPoint(x: 10, y: 180),
                                   bottomRight: CGPoint(x: 210, y: 180))
        )
    }

    /// A fixed-ratio crop (square crop box) that has been zoomed and flipped.
    private func makeFixedRatioCropInfo() -> CropInfo {
        CropInfo(
            translation: CGPoint(x: -5, y: 7),
            rotation: 0,
            scaleX: -1.5,
            scaleY: 1.5,
            cropSize: CGSize(width: 300, height: 300),
            imageViewSize: CGSize(width: 600, height: 400),
            cropRegion: CropRegion(topLeft: CGPoint(x: 0, y: 0),
                                   topRight: CGPoint(x: 300, y: 0),
                                   bottomLeft: CGPoint(x: 0, y: 300),
                                   bottomRight: CGPoint(x: 300, y: 300))
        )
    }

    /// A rotated crop with captured (identity-skew) view-reconstruction state.
    private func makeRotatedCropInfo() -> CropInfo {
        var info = CropInfo(
            translation: CGPoint(x: 3, y: 9),
            rotation: .pi / 6,
            scaleX: 1.2,
            scaleY: 1.2,
            cropSize: CGSize(width: 250, height: 180),
            imageViewSize: CGSize(width: 500, height: 400),
            cropRegion: CropRegion(topLeft: CGPoint(x: 40, y: 30),
                                   topRight: CGPoint(x: 290, y: 55),
                                   bottomLeft: CGPoint(x: 15, y: 210),
                                   bottomRight: CGPoint(x: 265, y: 235))
        )
        info.viewReconstruction = CropInfo.ViewReconstruction(
            skewSublayerTransform: CATransform3DIdentity,
            scrollContentOffset: CGPoint(x: 100, y: 80),
            scrollBoundsSize: CGSize(width: 250, height: 180),
            imageContainerFrame: CGRect(x: 0, y: 0, width: 600, height: 480),
            scrollViewTransform: CGAffineTransform(rotationAngle: .pi / 6)
        )
        return info
    }

    /// A perspective-skewed crop whose reconstruction carries a non-identity
    /// 3D sublayer transform and a rotated+flipped scroll-view transform.
    private func makePerspectiveCropInfo() -> CropInfo {
        var skew = CATransform3DIdentity
        skew.m34 = -1.0 / 500.0
        skew = CATransform3DRotate(skew, .pi / 9, 0, 1, 0)
        skew = CATransform3DTranslate(skew, 4, -6, 0)
        skew = CATransform3DScale(skew, 1.1, 0.95, 1)

        var info = CropInfo(
            translation: CGPoint(x: -8, y: 14),
            rotation: .pi / 12,
            scaleX: 1.3,
            scaleY: 1.3,
            cropSize: CGSize(width: 220, height: 300),
            imageViewSize: CGSize(width: 480, height: 640),
            cropRegion: CropRegion(topLeft: CGPoint(x: 30, y: 25),
                                   topRight: CGPoint(x: 250, y: 40),
                                   bottomLeft: CGPoint(x: 20, y: 320),
                                   bottomRight: CGPoint(x: 245, y: 335)),
            horizontalSkewDegrees: 12,
            verticalSkewDegrees: -7
        )
        info.viewReconstruction = CropInfo.ViewReconstruction(
            skewSublayerTransform: skew,
            scrollContentOffset: CGPoint(x: 60, y: 120),
            scrollBoundsSize: CGSize(width: 220, height: 300),
            imageContainerFrame: CGRect(x: -10, y: -15, width: 624, height: 832),
            scrollViewTransform: CGAffineTransform(rotationAngle: .pi / 12).scaledBy(x: -1, y: 1)
        )
        return info
    }

    /// A crop over a large image: geometry identical in shape to a normal crop,
    /// exercised through the CIImage path in the behavioral test below.
    private func makeLargeImageCropInfo(imageSize: CGSize,
                                        viewSize: CGSize,
                                        cropSize: CGSize,
                                        zoom: CGFloat,
                                        contentOffset: CGPoint) -> CropInfo {
        let containerCenter = CGPoint(x: viewSize.width * zoom / 2, y: viewSize.height * zoom / 2)
        let cropBoxCenter = CGPoint(x: contentOffset.x + cropSize.width / 2,
                                    y: contentOffset.y + cropSize.height / 2)
        var info = CropInfo(
            translation: CGPoint(x: containerCenter.x - cropBoxCenter.x,
                                 y: containerCenter.y - cropBoxCenter.y),
            rotation: 0,
            scaleX: zoom,
            scaleY: zoom,
            cropSize: cropSize,
            imageViewSize: viewSize,
            cropRegion: CropRegion(topLeft: .zero, topRight: .zero,
                                   bottomLeft: .zero, bottomRight: .zero)
        )
        info.viewReconstruction = CropInfo.ViewReconstruction(
            skewSublayerTransform: CATransform3DIdentity,
            scrollContentOffset: contentOffset,
            scrollBoundsSize: cropSize,
            imageContainerFrame: CGRect(origin: .zero,
                                        size: CGSize(width: viewSize.width * zoom,
                                                     height: viewSize.height * zoom)),
            scrollViewTransform: .identity
        )
        return info
    }

    // MARK: - Equality helpers

    private func assertEqual(_ lhs: CropInfo, _ rhs: CropInfo,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(lhs.translation, rhs.translation, "translation", file: file, line: line)
        XCTAssertEqual(lhs.rotation, rhs.rotation, "rotation", file: file, line: line)
        XCTAssertEqual(lhs.scaleX, rhs.scaleX, "scaleX", file: file, line: line)
        XCTAssertEqual(lhs.scaleY, rhs.scaleY, "scaleY", file: file, line: line)
        XCTAssertEqual(lhs.cropSize, rhs.cropSize, "cropSize", file: file, line: line)
        XCTAssertEqual(lhs.imageViewSize, rhs.imageViewSize, "imageViewSize", file: file, line: line)
        XCTAssertEqual(lhs.cropRegion, rhs.cropRegion, "cropRegion", file: file, line: line)
        XCTAssertEqual(lhs.horizontalSkewDegrees, rhs.horizontalSkewDegrees,
                       "horizontalSkewDegrees", file: file, line: line)
        XCTAssertEqual(lhs.verticalSkewDegrees, rhs.verticalSkewDegrees,
                       "verticalSkewDegrees", file: file, line: line)

        switch (lhs.viewReconstruction, rhs.viewReconstruction) {
        case (nil, nil):
            break
        case let (lvr?, rvr?):
            XCTAssertTrue(CATransform3DEqualToTransform(lvr.skewSublayerTransform,
                                                        rvr.skewSublayerTransform),
                          "skewSublayerTransform", file: file, line: line)
            XCTAssertEqual(lvr.scrollContentOffset, rvr.scrollContentOffset,
                           "scrollContentOffset", file: file, line: line)
            XCTAssertEqual(lvr.scrollBoundsSize, rvr.scrollBoundsSize,
                           "scrollBoundsSize", file: file, line: line)
            XCTAssertEqual(lvr.imageContainerFrame, rvr.imageContainerFrame,
                           "imageContainerFrame", file: file, line: line)
            XCTAssertEqual(lvr.scrollViewTransform, rvr.scrollViewTransform,
                           "scrollViewTransform", file: file, line: line)
        default:
            XCTFail("viewReconstruction presence differs", file: file, line: line)
        }
    }

    private func roundTripped(_ info: CropInfo,
                              file: StaticString = #filePath, line: UInt = #line) throws -> CropInfo {
        let data = try JSONEncoder().encode(info)
        return try JSONDecoder().decode(CropInfo.self, from: data)
    }

    // MARK: - Round-trip equality

    func testStandardCropInfoRoundTrips() throws {
        let info = makeStandardCropInfo()
        assertEqual(info, try roundTripped(info))
    }

    func testFixedRatioCropInfoRoundTrips() throws {
        let info = makeFixedRatioCropInfo()
        assertEqual(info, try roundTripped(info))
    }

    func testRotatedCropInfoRoundTrips() throws {
        let info = makeRotatedCropInfo()
        assertEqual(info, try roundTripped(info))
    }

    func testPerspectiveCropInfoRoundTrips() throws {
        let info = makePerspectiveCropInfo()
        assertEqual(info, try roundTripped(info))
    }

    /// A nil viewReconstruction (a CropInfo a caller builds directly) must
    /// survive the round-trip as nil, not become a zeroed struct.
    func testNilViewReconstructionRoundTripsAsNil() throws {
        let info = makeStandardCropInfo()
        XCTAssertNil(info.viewReconstruction)
        XCTAssertNil(try roundTripped(info).viewReconstruction)
    }

    // MARK: - Behavioral equivalence (decoded behaves like same-session)

    /// Draws a 4-quadrant colored pattern so any coordinate-space mistake
    /// changes sampled colors.
    private func makePatternImage(width: Int, height: Int) -> UIImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let halfW = CGFloat(width) / 2
        let halfH = CGFloat(height) / 2
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: halfW, height: halfH))
        context.setFillColor(UIColor.green.cgColor)
        context.fill(CGRect(x: halfW, y: 0, width: halfW, height: halfH))
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(x: 0, y: halfH, width: halfW, height: halfH))
        context.setFillColor(UIColor.yellow.cgColor)
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

    private func assertSameOutput(_ lhs: UIImage?, _ rhs: UIImage?,
                                  file: StaticString = #filePath, line: UInt = #line) {
        guard let lhs = lhs, let rhs = rhs else {
            XCTFail("crop returned nil", file: file, line: line); return
        }
        XCTAssertEqual(lhs.size.width, rhs.size.width, accuracy: 2.0, "width", file: file, line: line)
        XCTAssertEqual(lhs.size.height, rhs.size.height, accuracy: 2.0, "height", file: file, line: line)
        let samplePoints = [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25),
                            CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.75, y: 0.75),
                            CGPoint(x: 0.5, y: 0.5)]
        for point in samplePoints {
            guard let lhsPixel = pixel(of: lhs, atNormalized: point),
                  let rhsPixel = pixel(of: rhs, atNormalized: point) else {
                XCTFail("could not sample \(point)", file: file, line: line); continue
            }
            for channel in 0..<3 {
                XCTAssertEqual(lhsPixel[channel], rhsPixel[channel], accuracy: 0.1,
                               "pixel mismatch at \(point) channel \(channel)", file: file, line: line)
            }
        }
    }

    /// The legacy crop path produces the same image from a decoded CropInfo as
    /// from the original — the round-trip does not alter crop behavior.
    func testDecodedCropInfoProducesSameLegacyCrop() throws {
        let image = makePatternImage(width: 1000, height: 800)
        let info = makeLargeImageCropInfo(imageSize: image.size,
                                          viewSize: CGSize(width: 500, height: 400),
                                          cropSize: CGSize(width: 200, height: 160),
                                          zoom: 1,
                                          contentOffset: CGPoint(x: 150, y: 120))
        assertSameOutput(image.crop(by: info), image.crop(by: try roundTripped(info)))
    }

    /// The large-image (CIImage) crop path — which relies on the reconstructed
    /// view state — also produces the same image after a round-trip.
    func testDecodedCropInfoProducesSameCICrop() throws {
        let image = makePatternImage(width: 1000, height: 800)
        let info = makeLargeImageCropInfo(imageSize: image.size,
                                          viewSize: CGSize(width: 500, height: 400),
                                          cropSize: CGSize(width: 200, height: 160),
                                          zoom: 2,
                                          contentOffset: CGPoint(x: 400, y: 320))
        assertSameOutput(image.cropWithCIImage(by: info),
                         image.cropWithCIImage(by: try roundTripped(info)))
    }
}
