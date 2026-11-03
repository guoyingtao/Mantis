//
//  MantisFactoryTests.swift
//  MantisTests
//
//  Covers the public factory functions in Mantis.swift: how the appearance
//  mode is resolved into the toolbar, crop box, mask and dial configs, which
//  rotation control view gets attached to the crop view, the 1:1 ratio that
//  some crop shapes force, and the downsampled display image for large inputs.
//

import XCTest
@testable import Mantis

@MainActor
final class MantisFactoryTests: XCTestCase {
    private let image = TestHelper.createATestImage(bySize: CGSize(width: 40, height: 30))

    private func makeCropViewController(config: Mantis.Config = Mantis.Config(),
                                        rotationControlView: RotationControlViewProtocol? = nil) -> CropViewController {
        Mantis.cropViewController(image: image, config: config, rotationControlView: rotationControlView)
    }

    private func cropView(of cropViewController: CropViewController) throws -> CropView {
        try XCTUnwrap(cropViewController.cropView as? CropView)
    }

    private func config(appearanceMode: AppearanceMode) -> Mantis.Config {
        var config = Mantis.Config()
        config.appearanceMode = appearanceMode
        return config
    }

    // MARK: - Appearance defaults

    func testForceDarkKeepsDefaultColors() {
        let resolved = makeCropViewController().config

        XCTAssertEqual(resolved.cropViewConfig.appearanceMode, .forceDark)
        XCTAssertEqual(resolved.cropToolbarConfig.backgroundColor, .black)
        XCTAssertEqual(resolved.cropToolbarConfig.foregroundColor, .white)

        let auxiliaryConfig = resolved.cropViewConfig.cropAuxiliaryIndicatorConfig
        XCTAssertNil(auxiliaryConfig.borderNormalColor)
        XCTAssertNil(auxiliaryConfig.borderHintColor)
        XCTAssertNil(auxiliaryConfig.cornerHandleColor)
        XCTAssertNil(auxiliaryConfig.edgeLineHandleColor)

        guard case .blurDark = resolved.cropViewConfig.cropMaskVisualEffectType else {
            return XCTFail("Expected .blurDark, got \(resolved.cropViewConfig.cropMaskVisualEffectType)")
        }
    }

    func testForceLightAppliesLightPresetsToToolbarCropBoxAndMask() {
        let resolved = makeCropViewController(config: config(appearanceMode: .forceLight)).config

        XCTAssertEqual(resolved.cropViewConfig.appearanceMode, .forceLight)
        XCTAssertEqual(resolved.cropToolbarConfig.backgroundColor, AppearanceColorPreset.toolbarBackground(for: .forceLight))
        XCTAssertEqual(resolved.cropToolbarConfig.foregroundColor, AppearanceColorPreset.toolbarForeground(for: .forceLight))

        let expectedColor = AppearanceColorPreset.auxiliaryIndicatorColor(for: .forceLight)
        let auxiliaryConfig = resolved.cropViewConfig.cropAuxiliaryIndicatorConfig
        XCTAssertEqual(auxiliaryConfig.borderNormalColor, expectedColor)
        XCTAssertEqual(auxiliaryConfig.borderHintColor, expectedColor)
        XCTAssertEqual(auxiliaryConfig.cornerHandleColor, expectedColor)
        XCTAssertEqual(auxiliaryConfig.edgeLineHandleColor, expectedColor)

        guard case .light = resolved.cropViewConfig.cropMaskVisualEffectType else {
            return XCTFail("Expected .light, got \(resolved.cropViewConfig.cropMaskVisualEffectType)")
        }
    }

    func testForceLightKeepsCropBoxColorsSetByCaller() {
        var config = config(appearanceMode: .forceLight)
        config.cropViewConfig.cropAuxiliaryIndicatorConfig.borderNormalColor = .red
        config.cropViewConfig.cropAuxiliaryIndicatorConfig.cornerHandleColor = .green

        let auxiliaryConfig = makeCropViewController(config: config).config.cropViewConfig.cropAuxiliaryIndicatorConfig

        XCTAssertEqual(auxiliaryConfig.borderNormalColor, .red)
        XCTAssertEqual(auxiliaryConfig.cornerHandleColor, .green)
        // Only the colors left nil are filled from the preset.
        let expectedColor = AppearanceColorPreset.auxiliaryIndicatorColor(for: .forceLight)
        XCTAssertEqual(auxiliaryConfig.borderHintColor, expectedColor)
        XCTAssertEqual(auxiliaryConfig.edgeLineHandleColor, expectedColor)
    }

    func testForceLightKeepsMaskEffectOfExplicitBackgroundColor() {
        var config = config(appearanceMode: .forceLight)
        config.cropViewConfig.backgroundColor = .purple

        let resolved = makeCropViewController(config: config).config

        guard case .custom(let color) = resolved.cropViewConfig.cropMaskVisualEffectType else {
            return XCTFail("Expected .custom, got \(resolved.cropViewConfig.cropMaskVisualEffectType)")
        }
        XCTAssertEqual(color, .purple)
    }

    func testMaskOverlayUsesAppearancePresetWithoutBackgroundColor() throws {
        let cropView = try cropView(of: makeCropViewController(config: config(appearanceMode: .forceLight)))
        let maskViewManager = try XCTUnwrap(cropView.cropMaskViewManager as? CropMaskViewManager)

        XCTAssertEqual(maskViewManager.maskViews.count, 2)
        for maskView in maskViewManager.maskViews {
            XCTAssertEqual(maskView.overLayerFillColor, AppearanceColorPreset.dimmingOverlayColor(for: .forceLight))
        }
    }

    func testMaskOverlayUsesExplicitBackgroundColor() throws {
        var config = config(appearanceMode: .forceLight)
        config.cropViewConfig.backgroundColor = .purple

        let cropView = try cropView(of: makeCropViewController(config: config))
        let maskViewManager = try XCTUnwrap(cropView.cropMaskViewManager as? CropMaskViewManager)

        for maskView in maskViewManager.maskViews {
            XCTAssertEqual(maskView.overLayerFillColor, .purple)
        }
    }

    func testForceLightSetsLightRotationDialTheme() {
        let resolved = makeCropViewController(config: config(appearanceMode: .forceLight)).config

        guard case .rotationDial(let dialConfig) = resolved.cropViewConfig.builtInRotationControlViewType else {
            return XCTFail("Expected .rotationDial")
        }
        XCTAssertEqual(dialConfig.theme, .light)
    }

    func testForceLightAppliesSlideDialColors() throws {
        var config = config(appearanceMode: .forceLight)
        config.cropViewConfig.builtInRotationControlViewType = .slideDial()

        let cropViewController = makeCropViewController(config: config)

        guard case .slideDial(let slideDialConfig) = cropViewController.config.cropViewConfig.builtInRotationControlViewType else {
            return XCTFail("Expected .slideDial")
        }
        assertLightSlideDialColors(slideDialConfig)

        let slideDial = try XCTUnwrap(try cropView(of: cropViewController).rotationControlView as? SlideDial)
        assertLightSlideDialColors(slideDial.config)
    }

    private func assertLightSlideDialColors(_ config: SlideDialConfig, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(config.scaleColor, AppearanceColorPreset.slideDialScaleColor(for: .forceLight), file: file, line: line)
        XCTAssertEqual(config.majorScaleColor, AppearanceColorPreset.slideDialMajorScaleColor(for: .forceLight), file: file, line: line)
        XCTAssertEqual(config.inactiveColor, AppearanceColorPreset.slideDialInactiveColor(for: .forceLight), file: file, line: line)
        XCTAssertEqual(config.ringColor, AppearanceColorPreset.slideDialRingColor(for: .forceLight), file: file, line: line)
        XCTAssertEqual(config.buttonFillColor, AppearanceColorPreset.slideDialButtonFillColor(for: .forceLight), file: file, line: line)
        XCTAssertEqual(config.iconColor, AppearanceColorPreset.slideDialIconColor(for: .forceLight), file: file, line: line)
        XCTAssertEqual(config.centralDotColor, AppearanceColorPreset.slideDialCentralDotColor(for: .forceLight), file: file, line: line)
    }

    // MARK: - Rotation control view

    func testDefaultConfigAttachesRotationDial() throws {
        let cropView = try cropView(of: makeCropViewController())

        XCTAssertTrue(cropView.rotationControlView is RotationDial)
    }

    func testSlideDialConfigAttachesSimpleSlideDial() throws {
        var config = Mantis.Config()
        config.cropViewConfig.builtInRotationControlViewType = .slideDial()

        let slideDial = try XCTUnwrap(try cropView(of: makeCropViewController(config: config)).rotationControlView as? SlideDial)

        guard case .simple = slideDial.config.mode else {
            return XCTFail("Expected .simple, got \(slideDial.config.mode)")
        }
    }

    func testPerspectiveCorrectionReplacesRotationDialWithTypeSelectorSlideDial() throws {
        var config = Mantis.Config()
        config.cropViewConfig.enablePerspectiveCorrection = true

        let cropView = try cropView(of: makeCropViewController(config: config))
        let slideDial = try XCTUnwrap(cropView.rotationControlView as? SlideDial)

        guard case .withTypeSelector = slideDial.config.mode else {
            return XCTFail("Expected .withTypeSelector, got \(slideDial.config.mode)")
        }
        XCTAssertTrue(cropView.slideDialHandlesTypeSelection)
    }

    func testPerspectiveCorrectionSwitchesSlideDialToTypeSelectorMode() throws {
        var config = Mantis.Config()
        config.cropViewConfig.enablePerspectiveCorrection = true
        config.cropViewConfig.builtInRotationControlViewType = .slideDial()

        let slideDial = try XCTUnwrap(try cropView(of: makeCropViewController(config: config)).rotationControlView as? SlideDial)

        guard case .withTypeSelector = slideDial.config.mode else {
            return XCTFail("Expected .withTypeSelector, got \(slideDial.config.mode)")
        }
    }

    func testSlideDialSwappedInForPerspectiveCorrectionGetsAppearanceColors() throws {
        var config = config(appearanceMode: .forceLight)
        config.cropViewConfig.enablePerspectiveCorrection = true

        let slideDial = try XCTUnwrap(try cropView(of: makeCropViewController(config: config)).rotationControlView as? SlideDial)

        assertLightSlideDialColors(slideDial.config)
    }

    func testHiddenAttachedRotationControlLeavesNoRotationControlView() throws {
        var config = Mantis.Config()
        config.cropViewConfig.showAttachedRotationControlView = false

        XCTAssertNil(try cropView(of: makeCropViewController(config: config)).rotationControlView)
    }

    func testAttachedCustomRotationControlViewIsUsed() throws {
        let customView = FakeRotationDialView()

        let cropView = try cropView(of: makeCropViewController(rotationControlView: customView))

        XCTAssertTrue(cropView.rotationControlView === customView)
    }

    func testAttachedCustomRotationControlViewIsDroppedWhenAttachedControlIsHidden() throws {
        var config = Mantis.Config()
        config.cropViewConfig.showAttachedRotationControlView = false

        let cropView = try cropView(of: makeCropViewController(config: config, rotationControlView: FakeRotationDialView()))

        XCTAssertNil(cropView.rotationControlView)
    }

    func testDetachedCustomRotationControlViewIsUsedEvenWhenAttachedControlIsHidden() throws {
        var config = Mantis.Config()
        config.cropViewConfig.showAttachedRotationControlView = false
        let customView = FakeRotationDialView()
        customView.isAttachedToCropView = false

        let cropView = try cropView(of: makeCropViewController(config: config, rotationControlView: customView))

        XCTAssertTrue(cropView.rotationControlView === customView)
        // A detached control lives outside the crop view.
        XCTAssertNil(customView.superview)
    }

    // MARK: - Crop shapes

    func testRoundAndSquareShapesForceOneToOneRatio() {
        let shapes: [CropShapeType] = [.circle(), .circle(maskOnly: true), .square, .heart(), .heart(maskOnly: true)]

        for shape in shapes {
            var config = Mantis.Config()
            config.cropViewConfig.cropShapeType = shape

            let cropViewController = makeCropViewController(config: config)

            guard case .alwaysUsingOnePresetFixedRatio(let ratio) = cropViewController.config.presetFixedRatioType else {
                XCTFail("\(shape) should force a fixed ratio")
                continue
            }
            XCTAssertEqual(ratio, 1, "\(shape)")
        }
    }

    func testOtherShapesKeepPresetFixedRatioType() {
        let shapes: [CropShapeType] = [.rect, .ellipse(), .roundedRect(radiusToShortSide: 0.1), .diamond(), .polygon(sides: 5)]

        for shape in shapes {
            var config = Mantis.Config()
            config.cropViewConfig.cropShapeType = shape
            config.presetFixedRatioType = .canUseMultiplePresetFixedRatio(defaultRatio: 1.5)

            let cropViewController = makeCropViewController(config: config)

            guard case .canUseMultiplePresetFixedRatio(let defaultRatio) = cropViewController.config.presetFixedRatioType else {
                XCTFail("\(shape) should keep the caller's preset fixed ratio type")
                continue
            }
            XCTAssertEqual(defaultRatio, 1.5, "\(shape)")
        }
    }

    // MARK: - Factory variants

    func testGenericFactoryCreatesRequestedSubclass() {
        let cropViewController: CustomCropViewController = Mantis.cropViewController(image: image)

        XCTAssertTrue(cropViewController.cropView is CropView)
        XCTAssertTrue(cropViewController.cropToolbar is CropToolbar)
    }

    func testSetupCropViewControllerAppliesResolvedConfigAndToolbar() throws {
        let cropViewController = CropViewController()
        let toolbar = FakeCropToolbar()

        Mantis.setupCropViewController(cropViewController,
                                       with: image,
                                       and: config(appearanceMode: .forceLight),
                                       cropToolbar: toolbar)

        XCTAssertEqual(cropViewController.config.cropToolbarConfig.backgroundColor,
                       AppearanceColorPreset.toolbarBackground(for: .forceLight))
        XCTAssertTrue(cropViewController.cropToolbar === toolbar)
        XCTAssertTrue(cropViewController.cropView.image === image)
    }

    func testLargeImageIsDownsampledForDisplayButKeptForCropping() throws {
        let maxPixelCount = 1_000
        XCTAssertTrue(image.exceedsPixelCount(maxPixelCount))
        var config = Mantis.Config()
        config.cropViewConfig.maxImagePixelCount = maxPixelCount

        let cropView = try cropView(of: makeCropViewController(config: config))
        let imageView: UIImageView = try XCTUnwrap(cropView.imageContainer.findSubview(withAccessibilityIdentifier: "SourceImage"))
        let displayImage = try XCTUnwrap(imageView.image)

        XCTAssertTrue(cropView.image === image)
        XCTAssertFalse(displayImage.exceedsPixelCount(maxPixelCount))
    }
}

private final class CustomCropViewController: CropViewController {}
