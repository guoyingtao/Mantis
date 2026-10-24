//
//  CropViewControllerActionTests.swift
//  MantisTests
//
//  Covers how CropViewController handles toolbar actions and crop view
//  callbacks: registering undo steps only when the crop state really changed,
//  undo/redo applying the stored states back to the crop view, reset, the
//  preset fixed ratio branches when the toolbar is created, the ratio button,
//  cropping, and ignoring 90° rotations while one is still animating.
//

import XCTest
@testable import Mantis

@MainActor
final class CropViewControllerActionTests: XCTestCase {
    private var cropVC: CropViewController!
    private var fakeCropView: FakeCropView!
    private var fakeCropToolbar: FakeCropToolbar!
    private var fakeDelegate: FakeCropViewControllerDelegate!

    private let initialState = FakeCropView.makeState()
    private let editedState = FakeCropView.makeState(degrees: 12, horizontalSkewDegrees: 5)

    override func setUpWithError() throws {
        makeCropViewController()
    }

    private func makeCropViewController(config: Mantis.Config = Mantis.Config()) {
        cropVC = CropViewController(config: config)
        fakeCropView = FakeCropView()
        fakeCropToolbar = FakeCropToolbar()
        fakeDelegate = FakeCropViewControllerDelegate()
        cropVC.cropView = fakeCropView
        cropVC.cropToolbar = fakeCropToolbar
        cropVC.delegate = fakeDelegate
    }

    private func makeCropViewController(presetFixedRatioType: PresetFixedRatioType) {
        var config = Mantis.Config()
        config.presetFixedRatioType = presetFixedRatioType
        makeCropViewController(config: config)
    }

    private func enableUndoRedo() {
        // Changing config after init runs its didSet, which connects the undo stack.
        cropVC.config.enableUndoRedo = true
    }

    /// Simulates a user edit that the crop view reports through its delegate callbacks.
    private func performEdit(from previous: CropState, to current: CropState) {
        fakeCropView.cropState = previous
        cropVC.cropViewDidBeginResize(fakeCropView)
        fakeCropView.cropState = current
        cropVC.cropViewDidBecomeResettable(fakeCropView)
    }

    // MARK: - Registering undo steps

    func testEditThatChangesCropStateRegistersUndoStep() {
        enableUndoRedo()

        performEdit(from: initialState, to: editedState)

        XCTAssertEqual(cropVC.transformStack.top, 1)
        XCTAssertTrue(cropVC.isUndoEnabled())
        XCTAssertEqual(fakeDelegate.resetEnableStates.last, true)
        XCTAssertNil(cropVC.previousCropState)
    }

    func testEditThatKeepsCropStateDoesNotRegisterUndoStep() {
        enableUndoRedo()

        performEdit(from: initialState, to: initialState)

        XCTAssertEqual(cropVC.transformStack.top, 0)
        XCTAssertFalse(cropVC.isUndoEnabled())
        XCTAssertNil(cropVC.previousCropState)
    }

    func testEditIsNotRecordedWhenUndoRedoIsDisabled() {
        performEdit(from: initialState, to: editedState)

        XCTAssertNil(cropVC.previousCropState)
        XCTAssertEqual(cropVC.transformStack.top, 0)
        XCTAssertFalse(cropVC.isUndoEnabled())
        XCTAssertFalse(cropVC.isUndoSupported())
    }

    func testBecomingUnresettableAlsoRegistersUndoStep() {
        enableUndoRedo()
        fakeCropView.cropState = editedState
        cropVC.cropViewDidBeginResize(fakeCropView)
        fakeCropView.cropState = initialState

        cropVC.cropViewDidBecomeUnResettable(fakeCropView)

        XCTAssertEqual(cropVC.transformStack.top, 1)
        XCTAssertEqual(fakeDelegate.resettableStates, [false])
    }

    func testFlipSavesStateBeforeFlippingForUndo() {
        enableUndoRedo()
        fakeCropView.cropState = initialState

        cropVC.didSelectHorizontallyFlip()

        XCTAssertEqual(fakeCropView.horizontallyFlipCallCount, 1)
        XCTAssertEqual(cropVC.previousCropState, initialState)

        fakeCropView.cropState = editedState
        cropVC.cropViewDidBecomeResettable(fakeCropView)

        XCTAssertEqual(cropVC.transformStack.top, 1)
    }

    // MARK: - Undo / redo

    func testUndoAppliesPreviousStateAndRedoAppliesEditedState() {
        enableUndoRedo()
        performEdit(from: initialState, to: editedState)

        cropVC.undo()

        XCTAssertEqual(fakeCropView.appliedCropStates.last, initialState)
        XCTAssertEqual(cropVC.transformStack.top, 0)
        XCTAssertTrue(cropVC.isRedoEnabled())
        // Back at the bottom of the stack, there is nothing left to reset.
        XCTAssertEqual(fakeDelegate.resetEnableStates.last, false)

        cropVC.redo()

        XCTAssertEqual(fakeCropView.appliedCropStates.last, editedState)
        XCTAssertEqual(cropVC.transformStack.top, 1)
        XCTAssertTrue(cropVC.isUndoEnabled())
    }

    func testUndoAndRedoDoNothingWhenUndoRedoIsDisabled() {
        cropVC.undo()
        cropVC.redo()

        XCTAssertTrue(fakeCropView.appliedCropStates.isEmpty)
        XCTAssertFalse(cropVC.isRedoEnabled())
    }

    // MARK: - Reset

    func testResetRegistersResetUndoStepThatRestoresEditedState() {
        enableUndoRedo()
        fakeCropView.cropState = editedState
        fakeCropView.cropStateAfterReset = initialState

        cropVC.didSelectReset()

        XCTAssertEqual(fakeCropView.resetCallCount, 1)
        XCTAssertEqual(cropVC.transformStack.top, 1)
        // After a reset there is nothing left to reset.
        XCTAssertEqual(fakeDelegate.resetEnableStates.last, false)

        cropVC.undo()

        XCTAssertEqual(fakeCropView.appliedCropStates.last, editedState)
        XCTAssertEqual(fakeDelegate.resetEnableStates.last, true)
    }

    func testResetWithoutUndoRedoOnlyResetsCropView() {
        cropVC.didSelectReset()

        XCTAssertEqual(fakeCropView.resetCallCount, 1)
        XCTAssertEqual(cropVC.transformStack.top, 0)
    }

    func testResetUnlocksRatioWhenNoDefaultRatioIsPreset() {
        cropVC.didSelectReset()

        XCTAssertEqual(fakeCropView.setFreeCropCallCount, 1)
        XCTAssertTrue(fakeCropToolbar.didHandleFixedRatioUnSetted)
    }

    func testResetKeepsRatioLockedWhenRatioIsPreset() {
        let presets: [PresetFixedRatioType] = [
            .alwaysUsingOnePresetFixedRatio(ratio: 1.5),
            .canUseMultiplePresetFixedRatio(defaultRatio: 1.5)
        ]

        for preset in presets {
            makeCropViewController(presetFixedRatioType: preset)

            cropVC.didSelectReset()

            XCTAssertEqual(fakeCropView.resetCallCount, 1, "\(preset)")
            XCTAssertEqual(fakeCropView.setFreeCropCallCount, 0, "\(preset)")
            XCTAssertFalse(fakeCropToolbar.didHandleFixedRatioUnSetted, "\(preset)")
        }
    }

    // MARK: - Creating the toolbar

    func testCreateCropToolbarConnectsToolbarDelegate() {
        cropVC.createCropToolbar()

        XCTAssertTrue(fakeCropToolbar.delegate === cropVC)
    }

    func testSinglePresetRatioLocksRatioAndHidesRatioButton() {
        makeCropViewController(presetFixedRatioType: .alwaysUsingOnePresetFixedRatio(ratio: 1.5))

        cropVC.createCropToolbar()

        XCTAssertEqual(fakeCropView.setFixedRatioCalls.map { $0.ratio }, [1.5])
        XCTAssertEqual(fakeCropToolbar.fixedRatiosSetted, [1.5])
        XCTAssertFalse(fakeCropToolbar.config.includeFixedRatiosSettingButton)
    }

    func testSinglePresetRatioWaitsForPresetTransformation() {
        var config = Mantis.Config()
        config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1.5)
        config.cropViewConfig.presetTransformationType = .presetNormalizedInfo(normalizedInfo: CGRect(x: 0, y: 0, width: 1, height: 1))
        makeCropViewController(config: config)

        cropVC.createCropToolbar()

        // The ratio is applied after the preset transformation, in viewDidLayoutSubviews.
        XCTAssertTrue(fakeCropView.setFixedRatioCalls.isEmpty)
        XCTAssertFalse(fakeCropToolbar.config.includeFixedRatiosSettingButton)
    }

    func testDefaultPresetRatioLocksRatioAndSelectsRatioButton() {
        makeCropViewController(presetFixedRatioType: .canUseMultiplePresetFixedRatio(defaultRatio: 4.0 / 3.0))

        cropVC.createCropToolbar()

        XCTAssertEqual(fakeCropView.setFixedRatioCalls.map { $0.ratio }, [4.0 / 3.0])
        XCTAssertTrue(fakeCropView.aspectRatioLockEnabled)
        XCTAssertTrue(fakeCropToolbar.config.presetRatiosButtonSelected)
        XCTAssertTrue(fakeCropToolbar.config.includeFixedRatiosSettingButton)
    }

    func testNoDefaultRatioLeavesRatioUnlocked() {
        cropVC.createCropToolbar()

        XCTAssertTrue(fakeCropView.setFixedRatioCalls.isEmpty)
        XCTAssertFalse(fakeCropView.aspectRatioLockEnabled)
        XCTAssertFalse(fakeCropToolbar.config.presetRatiosButtonSelected)
        XCTAssertTrue(fakeCropToolbar.config.includeFixedRatiosSettingButton)
    }

    // MARK: - Ratio button

    func testRatioButtonUnlocksLockedRatioWhenNoDefaultRatioIsPreset() {
        fakeCropView.aspectRatioLockEnabled = true
        fakeCropToolbar.ratioListPresentSourceView = UIView()

        cropVC.didSelectSetRatio()

        XCTAssertEqual(fakeCropView.setFreeCropCallCount, 1)
        XCTAssertTrue(fakeCropToolbar.didHandleFixedRatioUnSetted)
        XCTAssertNil(cropVC.ratioPresenter)
    }

    func testRatioButtonDoesNothingWithoutPresentSourceView() {
        cropVC.didSelectSetRatio()

        XCTAssertTrue(fakeCropView.setFixedRatioCalls.isEmpty)
        XCTAssertNil(cropVC.ratioPresenter)
    }

    func testRatioButtonDoesNothingWithoutRatioOptions() {
        var config = Mantis.Config()
        config.ratioOptions = []
        makeCropViewController(config: config)
        fakeCropToolbar.ratioListPresentSourceView = UIView()

        cropVC.didSelectSetRatio()

        XCTAssertTrue(fakeCropView.setFixedRatioCalls.isEmpty)
        XCTAssertNil(cropVC.ratioPresenter)
    }

    func testRatioButtonAppliesTheOnlyRatioDirectly() {
        var config = Mantis.Config()
        config.ratioOptions = .square
        makeCropViewController(config: config)
        fakeCropToolbar.ratioListPresentSourceView = UIView()

        cropVC.didSelectSetRatio()

        XCTAssertEqual(fakeCropView.setFixedRatioCalls.map { $0.ratio }, [1])
        XCTAssertEqual(fakeCropToolbar.fixedRatiosSetted, [1])
        XCTAssertNil(cropVC.ratioPresenter)
    }

    func testRatioButtonPresentsListWhenThereAreSeveralRatios() throws {
        fakeCropView.imageHorizontalToVerticalRatio = 1.5
        fakeCropToolbar.ratioListPresentSourceView = UIView()

        cropVC.didSelectSetRatio()

        XCTAssertTrue(fakeCropView.setFixedRatioCalls.isEmpty)
        let ratioPresenter = try XCTUnwrap(cropVC.ratioPresenter)

        // Picking a ratio from the list keeps the current zoom.
        ratioPresenter.didGetRatio(16.0 / 9.0)

        XCTAssertEqual(fakeCropView.setFixedRatioCalls.count, 1)
        XCTAssertEqual(fakeCropView.setFixedRatioCalls.first?.ratio, 16.0 / 9.0)
        XCTAssertEqual(fakeCropView.setFixedRatioCalls.first?.zoom, false)
    }

    // MARK: - Cropping

    func testCropFailureNotifiesDelegate() {
        fakeCropView.croppedImage = nil

        cropVC.crop()

        XCTAssertTrue(fakeDelegate.didFailedToCrop)
        XCTAssertFalse(fakeDelegate.didCrop)
    }

    func testCropSuccessNotifiesDelegate() {
        fakeCropView.croppedImage = TestHelper.createATestImage(bySize: CGSize(width: 10, height: 10))

        cropVC.crop()

        XCTAssertTrue(fakeDelegate.didCrop)
        XCTAssertFalse(fakeDelegate.didFailedToCrop)
    }

    func testAsyncCropModeNotifiesDelegate() {
        var config = Mantis.Config()
        config.cropMode = .async
        makeCropViewController(config: config)
        fakeCropView.croppedImage = TestHelper.createATestImage(bySize: CGSize(width: 10, height: 10))

        cropVC.crop()

        XCTAssertTrue(fakeDelegate.didCrop)
    }

    // MARK: - 90° rotation

    func testRotationIsIgnoredUntilPreviousRotationFinishes() throws {
        cropVC.didSelectClockwiseRotate()
        cropVC.didSelectCounterClockwiseRotate()

        XCTAssertEqual(fakeCropView.rotateBy90Types, [.clockwise])

        let finishRotation = try XCTUnwrap(fakeCropView.pendingRotationCompletions.first)
        finishRotation()
        cropVC.didSelectCounterClockwiseRotate()

        XCTAssertEqual(fakeCropView.rotateBy90Types, [.clockwise, .counterClockwise])
    }
}
