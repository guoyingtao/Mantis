//
//  TransformStackTests.swift
//  MantisTests
//
//  Created by Richard Shane on 24/3/2024.
//

import XCTest
@testable import Mantis

final class TransformStackTests: XCTestCase {

    var cropVC: CropViewController!
    var cropView: CropView!
    var cropViewModel: CropViewModelProtocol = CropViewModel(cropViewPadding: 0, hotAreaUnit: 0)

    private func createCropView(with image: UIImage = UIImage(),
                                cropViewConfig: CropViewConfig = CropViewConfig(),
                                viewModel: CropViewModelProtocol) -> CropView {
        CropView(image: image,
                 cropViewConfig: cropViewConfig,
                 viewModel: viewModel,
                 cropAuxiliaryIndicatorView: FakeCropAuxiliaryIndicatorView(frame: .zero),
                 imageContainer: FakeImageContainer(frame: .zero),
                 cropWorkbenchView: FakeCropWorkbenchView(frame: .zero),
                 cropMaskViewManager: FakeCropMaskViewManager())
    }

    private func createCropViewController() -> CropViewController {
        var config = Config()
        config.enableUndoRedo = true
        let cropViewController = CropViewController(config: config)
        cropViewController.cropView = createCropView(cropViewConfig: config.cropViewConfig, viewModel: cropViewModel)
        cropViewController.transformStack.transformDelegate = cropViewController
        return cropViewController
    }

    override func setUpWithError() throws {
        cropVC = createCropViewController()
        cropView = (cropVC.cropView as? CropView)
        XCTAssertEqual(cropVC.transformStack.top, 0)
    }

    func testApplyRecords() {
        let stack = cropVC.transformStack

        var previousState = cropView.makeCropState()
        var currentState = cropView.makeCropState()

        stack.pushTransformRecordOntoStack(transformType: .transform,
                                           previous: previousState,
                                           current: currentState,
                                           userGenerated: true)
        XCTAssertEqual(stack.top, 1)

        previousState = cropView.makeCropState()
        currentState = cropView.makeCropState()

        stack.pushTransformRecordOntoStack(transformType: .resetTransforms,
                                           previous: previousState,
                                           current: currentState,
                                           userGenerated: true)

        XCTAssertEqual(stack.top, 2)
        stack.popTransformStack()
        XCTAssertEqual(stack.top, 1)
        stack.popTransformStack()
        XCTAssertEqual(stack.top, 0)
        stack.popTransformStack()
        XCTAssertEqual(stack.top, 0)
    }

    func testStacksAreIndependentAcrossControllers() {
        let otherCropVC = createCropViewController()

        XCTAssertFalse(cropVC.transformStack === otherCropVC.transformStack)

        let previousState = cropView.makeCropState()
        let currentState = cropView.makeCropState()

        cropVC.transformStack.pushTransformRecordOntoStack(transformType: .transform,
                                                           previous: previousState,
                                                           current: currentState,
                                                           userGenerated: true)

        XCTAssertEqual(cropVC.transformStack.top, 1)
        // A second concurrent crop session must not see the first session's records.
        XCTAssertEqual(otherCropVC.transformStack.top, 0)

        otherCropVC.transformStack.reset()
        XCTAssertEqual(cropVC.transformStack.top, 1)
    }

    func testUndoManagersAreIndependentAcrossControllers() {
        let otherCropVC = createCropViewController()

        let previousState = cropView.makeCropState()
        let currentState = cropView.makeCropState()

        cropVC.transformStack.pushTransformRecordOntoStack(transformType: .transform,
                                                           previous: previousState,
                                                           current: currentState,
                                                           userGenerated: true)

        XCTAssertTrue(cropVC.getUndoManager().canUndo)
        XCTAssertFalse(otherCropVC.getUndoManager().canUndo)
    }
}
