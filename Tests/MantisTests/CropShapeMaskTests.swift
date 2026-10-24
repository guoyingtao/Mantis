//
//  CropShapeMaskTests.swift
//  MantisTests
//
//  Covers CropView.addImageMask(to:), which turns the rectangular crop result
//  into the configured CropShapeType: which shapes clip the output (making the
//  area outside the shape transparent), which keep it rectangular because
//  maskOnly is set, the optional border, and the degenerate shapes that make
//  the crop fail.
//

import XCTest
@testable import Mantis

final class CropShapeMaskTests: XCTestCase {
    private let imageSize = CGSize(width: 100, height: 100)
    private let triangle = [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)]

    private func makeSolidImage(color: UIColor = .red) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: imageSize, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
        }
    }

    private func makeCropView(shape: CropShapeType, borderWidth: CGFloat = 0, borderColor: UIColor = .clear) -> CropView {
        var config = CropViewConfig()
        config.cropShapeType = shape
        if borderWidth > 0 {
            config.cropBorderWidth = borderWidth
        }
        config.cropBorderColor = borderColor

        return CropView(image: makeSolidImage(),
                        cropViewConfig: config,
                        viewModel: CropViewModel(cropViewPadding: 0, hotAreaUnit: 0),
                        cropAuxiliaryIndicatorView: FakeCropAuxiliaryIndicatorView(frame: .zero),
                        imageContainer: FakeImageContainer(frame: .zero),
                        cropWorkbenchView: FakeCropWorkbenchView(frame: .zero),
                        cropMaskViewManager: FakeCropMaskViewManager())
    }

    private func mask(_ image: UIImage, shape: CropShapeType, borderWidth: CGFloat = 0, borderColor: UIColor = .clear) -> UIImage? {
        let cropInfo = CropInfo(translation: .zero, rotation: 0,
                                scaleX: 1, scaleY: 1,
                                cropSize: imageSize, imageViewSize: imageSize,
                                cropRegion: CropRegion(topLeft: .zero, topRight: .zero,
                                                       bottomLeft: .zero, bottomRight: .zero))
        let cropView = makeCropView(shape: shape, borderWidth: borderWidth, borderColor: borderColor)
        return cropView.addImageMask(to: (image, FakeCropView.makeEmptyTransformation(), cropInfo)).croppedImage
    }

    /// Reads the premultiplied RGBA components of the pixel at (x, y), measured from the top-left.
    private func pixel(of image: UIImage, x posX: Int, y posY: Int) -> [CGFloat]? {
        guard let cgImage = image.cgImage else { return nil }
        var data = [UInt8](repeating: 0, count: 4)
        let drawn = data.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: 1, height: 1,
                                          bitsPerComponent: 8, bytesPerRow: 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                return false
            }
            context.draw(cgImage, in: CGRect(x: -CGFloat(posX),
                                             y: CGFloat(posY) - CGFloat(cgImage.height) + 1,
                                             width: CGFloat(cgImage.width),
                                             height: CGFloat(cgImage.height)))
            return true
        }
        return drawn ? data.map { CGFloat($0) / 255 } : nil
    }

    private func assertTransparent(_ image: UIImage, x posX: Int, y posY: Int, _ message: String,
                                   file: StaticString = #filePath, line: UInt = #line) {
        guard let pixel = pixel(of: image, x: posX, y: posY) else {
            return XCTFail("Could not read pixel (\(posX), \(posY)): \(message)", file: file, line: line)
        }
        XCTAssertEqual(pixel[3], 0, accuracy: 0.01, "(\(posX), \(posY)) should be transparent: \(message)", file: file, line: line)
    }

    private func assertColor(_ image: UIImage, x posX: Int, y posY: Int, _ expected: [CGFloat], _ message: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        guard let pixel = pixel(of: image, x: posX, y: posY) else {
            return XCTFail("Could not read pixel (\(posX), \(posY)): \(message)", file: file, line: line)
        }
        for channel in 0..<4 {
            XCTAssertEqual(pixel[channel], expected[channel], accuracy: 0.01,
                           "(\(posX), \(posY)) is \(pixel), expected \(expected): \(message)", file: file, line: line)
        }
    }

    private let opaqueRed: [CGFloat] = [1, 0, 0, 1]
    private let opaqueBlue: [CGFloat] = [0, 0, 1, 1]

    // MARK: - Shapes that clip the output

    func testClippingShapesMakeCornersTransparentAndKeepCenter() throws {
        let shapes: [CropShapeType] = [
            .ellipse(),
            .circle(),
            .roundedRect(radiusToShortSide: 0.2),
            .diamond(),
            .heart(),
            .polygon(sides: 6),
            .path(points: triangle)
        ]
        let image = makeSolidImage()

        for shape in shapes {
            let output = try XCTUnwrap(mask(image, shape: shape), "\(shape)")

            XCTAssertEqual(output.size, imageSize, "\(shape)")
            assertTransparent(output, x: 1, y: 1, "\(shape)")
            assertColor(output, x: 50, y: 50, opaqueRed, "\(shape)")
        }
    }

    func testHeartShapeClipsBottomCorners() throws {
        let output = try XCTUnwrap(mask(makeSolidImage(), shape: .heart()))

        assertTransparent(output, x: 1, y: 98, "bottom left")
        assertTransparent(output, x: 98, y: 98, "bottom right")
        // The point of the heart sits at the bottom center.
        assertColor(output, x: 50, y: 85, opaqueRed, "bottom point")
    }

    func testRoundedRectKeepsEdgeMidpoints() throws {
        let output = try XCTUnwrap(mask(makeSolidImage(), shape: .roundedRect(radiusToShortSide: 0.2)))

        assertTransparent(output, x: 1, y: 1, "top left corner")
        assertColor(output, x: 50, y: 1, opaqueRed, "top edge midpoint")
        assertColor(output, x: 1, y: 50, opaqueRed, "left edge midpoint")
    }

    // MARK: - Shapes that keep a rectangular output

    func testRectWithoutBorderReturnsCroppedImageUnchanged() throws {
        let image = makeSolidImage()

        let output = try XCTUnwrap(mask(image, shape: .rect))

        XCTAssertTrue(output === image)
    }

    func testMaskOnlyShapesKeepRectangularOutput() throws {
        let shapes: [CropShapeType] = [
            .square,
            .circle(maskOnly: true),
            .roundedRect(radiusToShortSide: 0.2, maskOnly: true),
            .diamond(maskOnly: true),
            .heart(maskOnly: true),
            .polygon(sides: 6, maskOnly: true),
            .path(points: triangle, maskOnly: true)
        ]
        let image = makeSolidImage()

        for shape in shapes {
            let output = try XCTUnwrap(mask(image, shape: shape), "\(shape)")
            XCTAssertTrue(output === image, "\(shape) should not clip the output")
        }
    }

    func testEllipseMaskOnlyKeepsRectangularOutput() throws {
        // .ellipse(maskOnly: true) used to fall through to the ellipse mask.
        let image = makeSolidImage()

        let output = try XCTUnwrap(mask(image, shape: .ellipse(maskOnly: true)))

        XCTAssertTrue(output === image)
    }

    func testBorderIsDrawnInsideRectangularOutput() throws {
        let output = try XCTUnwrap(mask(makeSolidImage(), shape: .rect, borderWidth: 4, borderColor: .blue))

        XCTAssertEqual(output.size, imageSize)
        assertColor(output, x: 3, y: 50, opaqueBlue, "left border")
        assertColor(output, x: 96, y: 50, opaqueBlue, "right border")
        assertColor(output, x: 50, y: 50, opaqueRed, "center")
    }

    func testMaskOnlyShapeWithBorderGetsRectangularBorder() throws {
        let output = try XCTUnwrap(mask(makeSolidImage(), shape: .circle(maskOnly: true), borderWidth: 4, borderColor: .blue))

        // The corner region stays filled, so the output is not clipped to the circle.
        assertColor(output, x: 3, y: 3, opaqueBlue, "top left border")
        assertColor(output, x: 10, y: 10, opaqueRed, "inside the top left corner")
    }

    // MARK: - Degenerate shapes

    func testPathWithFewerThanThreePointsFailsToCrop() {
        let shape = CropShapeType.path(points: [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1)])

        XCTAssertNil(mask(makeSolidImage(), shape: shape))
    }

    func testPolygonWithoutSidesFailsToCrop() {
        XCTAssertNil(mask(makeSolidImage(), shape: .polygon(sides: 0)))
        XCTAssertNil(mask(makeSolidImage(), shape: .polygon(sides: -3)))
    }

    // MARK: - polygonPointArray

    func testPolygonPointsAreClosedAndLieOnTheCircle() {
        let sides = 6
        let points = polygonPointArray(sides: sides, originX: 0.5, originY: 0.5, radius: 0.5, offset: 90)

        XCTAssertEqual(points.count, sides + 1)
        XCTAssertEqual(points[0].x, points[sides].x, accuracy: 1e-9)
        XCTAssertEqual(points[0].y, points[sides].y, accuracy: 1e-9)
        for point in points {
            XCTAssertEqual(hypot(point.x - 0.5, point.y - 0.5), 0.5, accuracy: 1e-9)
        }
    }

    func testPolygonOffsetOfNinetyDegreesStartsAtTopCenter() {
        // addImageMask(to:) and the mask view pass 90 + offset, so a polygon with
        // no offset points straight up.
        let points = polygonPointArray(sides: 5, originX: 0.5, originY: 0.5, radius: 0.5, offset: 90)

        XCTAssertEqual(points[0].x, 0.5, accuracy: 1e-9)
        XCTAssertEqual(points[0].y, 0, accuracy: 1e-9)
    }
}
