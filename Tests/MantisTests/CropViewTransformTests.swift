//
//  CropViewTransformTests.swift
//  MantisTests
//
//  Covers how CropView converts between its state and the values it hands out
//  or restores: the flip signs in getCropInfo(), splitting a stored total
//  rotation back into a 90° step and a straighten angle (used by undo/redo and
//  preset transformations), and turning a normalized crop rect into a
//  Transformation.
//

import XCTest
@testable import Mantis

final class CropViewTransformTests: XCTestCase {
    private var viewModel: CropViewModel!
    private var cropView: CropView!

    private let allRotationTypes: [ImageRotationType] = [.none, .counterclockwise90, .counterclockwise180, .counterclockwise270]

    override func setUpWithError() throws {
        viewModel = CropViewModel(cropViewPadding: 0, hotAreaUnit: 0)
        cropView = CropView(image: TestHelper.createATestImage(bySize: CGSize(width: 200, height: 100)),
                            cropViewConfig: CropViewConfig(),
                            viewModel: viewModel,
                            cropAuxiliaryIndicatorView: FakeCropAuxiliaryIndicatorView(frame: .zero),
                            imageContainer: FakeImageContainer(frame: .zero),
                            cropWorkbenchView: FakeCropWorkbenchView(frame: .zero),
                            cropMaskViewManager: FakeCropMaskViewManager())
    }

    // MARK: - getCropInfo flip signs

    private func assertScaleSigns(horizontallyFlip: Bool,
                                  verticallyFlip: Bool,
                                  rotationType: ImageRotationType,
                                  expectedX: CGFloat,
                                  expectedY: CGFloat,
                                  file: StaticString = #filePath,
                                  line: UInt = #line) {
        viewModel.horizontallyFlip = horizontallyFlip
        viewModel.verticallyFlip = verticallyFlip
        viewModel.rotationType = rotationType

        let cropInfo = cropView.getCropInfo()
        let zoomScale = cropView.cropWorkbenchView.zoomScale
        let context = "hFlip: \(horizontallyFlip), vFlip: \(verticallyFlip), rotation: \(rotationType)"

        XCTAssertEqual(cropInfo.scaleX, expectedX * zoomScale, context, file: file, line: line)
        XCTAssertEqual(cropInfo.scaleY, expectedY * zoomScale, context, file: file, line: line)
    }

    func testCropInfoScaleIsPositiveWithoutFlip() {
        for rotationType in allRotationTypes {
            assertScaleSigns(horizontallyFlip: false, verticallyFlip: false, rotationType: rotationType,
                             expectedX: 1, expectedY: 1)
        }
    }

    func testHorizontalFlipNegatesScaleXWhenUprightAndScaleYWhenSideways() {
        assertScaleSigns(horizontallyFlip: true, verticallyFlip: false, rotationType: .none, expectedX: -1, expectedY: 1)
        assertScaleSigns(horizontallyFlip: true, verticallyFlip: false, rotationType: .counterclockwise180, expectedX: -1, expectedY: 1)
        assertScaleSigns(horizontallyFlip: true, verticallyFlip: false, rotationType: .counterclockwise90, expectedX: 1, expectedY: -1)
        assertScaleSigns(horizontallyFlip: true, verticallyFlip: false, rotationType: .counterclockwise270, expectedX: 1, expectedY: -1)
    }

    func testVerticalFlipNegatesScaleYWhenUprightAndScaleXWhenSideways() {
        assertScaleSigns(horizontallyFlip: false, verticallyFlip: true, rotationType: .none, expectedX: 1, expectedY: -1)
        assertScaleSigns(horizontallyFlip: false, verticallyFlip: true, rotationType: .counterclockwise180, expectedX: 1, expectedY: -1)
        assertScaleSigns(horizontallyFlip: false, verticallyFlip: true, rotationType: .counterclockwise90, expectedX: -1, expectedY: 1)
        assertScaleSigns(horizontallyFlip: false, verticallyFlip: true, rotationType: .counterclockwise270, expectedX: -1, expectedY: 1)
    }

    func testFlippingBothWaysNegatesBothScales() {
        for rotationType in allRotationTypes {
            assertScaleSigns(horizontallyFlip: true, verticallyFlip: true, rotationType: rotationType,
                             expectedX: -1, expectedY: -1)
        }
    }

    func testCropInfoCarriesRotationSkewAndViewReconstruction() throws {
        viewModel.rotationType = .counterclockwise90
        viewModel.degrees = 12
        viewModel.horizontalSkewDegrees = 5
        viewModel.verticalSkewDegrees = -7
        cropView.cropWorkbenchView.transform = CGAffineTransform(rotationAngle: 0.3)

        let cropInfo = cropView.getCropInfo()

        XCTAssertEqual(cropInfo.rotation, viewModel.getTotalRadians(), accuracy: 1e-12)
        XCTAssertEqual(cropInfo.horizontalSkewDegrees, 5)
        XCTAssertEqual(cropInfo.verticalSkewDegrees, -7)
        let reconstruction = try XCTUnwrap(cropInfo.viewReconstruction)
        XCTAssertEqual(reconstruction.scrollViewTransform, cropView.cropWorkbenchView.transform)
    }

    // MARK: - decomposeRotation

    func testDecomposeRotationInvertsTotalRadians() {
        // CropViewModel.getTotalRadians() adds the 90° step to the straighten
        // angle; transform(byTransformInfo:) relies on decomposeRotation to undo it.
        for rotationType in allRotationTypes {
            for degrees in stride(from: CGFloat(-44), through: 44, by: 4) {
                viewModel.rotationType = rotationType
                viewModel.degrees = degrees

                let (decomposedType, freeRadians) = cropView.decomposeRotation(totalRadians: viewModel.getTotalRadians())

                XCTAssertEqual(decomposedType, rotationType, "\(rotationType) + \(degrees)°")
                XCTAssertEqual(freeRadians * 180 / .pi, degrees, accuracy: 1e-9, "\(rotationType) + \(degrees)°")
            }
        }
    }

    func testDecomposeRotationInvertsClampedStraightenLimit() {
        // clampAngle keeps the straighten angle just inside ±45°, where rounding
        // to the nearest 90° step is closest to ambiguous.
        let limits = [cropView.clampAngle(Angle(degrees: 60)), cropView.clampAngle(Angle(degrees: -60))]

        for rotationType in allRotationTypes {
            for limit in limits {
                viewModel.rotationType = rotationType
                viewModel.degrees = limit.degrees

                let (decomposedType, freeRadians) = cropView.decomposeRotation(totalRadians: viewModel.getTotalRadians())

                XCTAssertEqual(decomposedType, rotationType, "\(rotationType) + \(limit.degrees)°")
                XCTAssertEqual(freeRadians, limit.radians, accuracy: 1e-9, "\(rotationType) + \(limit.degrees)°")
            }
        }
    }

    func testDecomposeRotationNormalizesEquivalentQuarterTurns() {
        let cases: [(degrees: CGFloat, rotationType: ImageRotationType, freeDegrees: CGFloat)] = [
            (90, .counterclockwise270, 0),
            (180, .counterclockwise180, 0),
            (270, .counterclockwise90, 0),
            (360, .none, 0),
            (-360, .none, 0),
            (370, .none, 10),
            (-450, .counterclockwise90, 0),
            (-300, .counterclockwise270, -30)
        ]

        for testCase in cases {
            let (rotationType, freeRadians) = cropView.decomposeRotation(totalRadians: testCase.degrees * .pi / 180)

            XCTAssertEqual(rotationType, testCase.rotationType, "\(testCase.degrees)°")
            XCTAssertEqual(freeRadians * 180 / .pi, testCase.freeDegrees, accuracy: 1e-9, "\(testCase.degrees)°")
        }
    }

    func testTransformRestoresRotationTypeAndStraightenAngle() {
        var transformation = FakeCropView.makeEmptyTransformation()
        transformation.scale = 1
        transformation.rotation = (-90 + 20) * .pi / 180

        cropView.transform(byTransformInfo: transformation, isUpdateRotationControlView: false)

        XCTAssertEqual(viewModel.rotationType, .counterclockwise90)
        XCTAssertEqual(viewModel.degrees, 20, accuracy: 1e-9)
    }

    // MARK: - getTransformInfo(byNormalizedInfo:)

    private func transformation(forNormalizedRect normalizedRect: CGRect) -> Transformation {
        viewModel.cropBoxFrame = CGRect(x: 10, y: 20, width: 200, height: 100)
        return cropView.getTransformInfo(byNormalizedInfo: normalizedRect)
    }

    func testFullImageNormalizedRectKeepsCropBoxUnzoomed() {
        let transformation = transformation(forNormalizedRect: CGRect(x: 0, y: 0, width: 1, height: 1))

        XCTAssertEqual(transformation.scale, 1)
        XCTAssertFalse(transformation.isManuallyZoomed)
        XCTAssertEqual(transformation.offset, .zero)
        XCTAssertEqual(transformation.maskFrame, CGRect(x: 10, y: 20, width: 200, height: 100))
        XCTAssertEqual(transformation.rotation, 0)
    }

    func testCenteredNormalizedRectZoomsIn() {
        let transformation = transformation(forNormalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))

        XCTAssertEqual(transformation.scale, 2)
        XCTAssertTrue(transformation.isManuallyZoomed)
        XCTAssertEqual(transformation.offset, CGPoint(x: 100, y: 50))
        XCTAssertEqual(transformation.maskFrame, CGRect(x: 10, y: 20, width: 200, height: 100))
    }

    func testWideNormalizedRectShrinksMaskHeightAroundCenter() {
        let transformation = transformation(forNormalizedRect: CGRect(x: 0.1, y: 0.2, width: 0.4, height: 0.2))

        XCTAssertEqual(transformation.scale, 2.5, accuracy: 1e-9)
        XCTAssertEqual(transformation.offset.x, 50, accuracy: 1e-9)
        XCTAssertEqual(transformation.offset.y, 50, accuracy: 1e-9)
        XCTAssertEqual(transformation.maskFrame.minX, 10, accuracy: 1e-9)
        XCTAssertEqual(transformation.maskFrame.minY, 45, accuracy: 1e-9)
        XCTAssertEqual(transformation.maskFrame.width, 200, accuracy: 1e-9)
        XCTAssertEqual(transformation.maskFrame.height, 50, accuracy: 1e-9)
    }

    func testTallNormalizedRectShrinksMaskWidthAroundCenter() {
        let transformation = transformation(forNormalizedRect: CGRect(x: 0.5, y: 0, width: 0.5, height: 1))

        XCTAssertEqual(transformation.scale, 1)
        XCTAssertFalse(transformation.isManuallyZoomed)
        XCTAssertEqual(transformation.offset, CGPoint(x: 100, y: 0))
        XCTAssertEqual(transformation.maskFrame, CGRect(x: 60, y: 20, width: 100, height: 100))
    }

    func testNormalizedRectTransformationKeepsFlipState() {
        viewModel.horizontallyFlip = true
        viewModel.verticallyFlip = false

        let transformation = transformation(forNormalizedRect: CGRect(x: 0, y: 0, width: 1, height: 1))

        XCTAssertTrue(transformation.horizontallyFlipped)
        XCTAssertFalse(transformation.verticallyFlipped)
    }
}
