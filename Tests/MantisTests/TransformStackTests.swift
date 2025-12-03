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
    
    override func setUpWithError() throws {
        
        var config = Config()
        config.enableUndoRedo = true
        cropView = createCropView(cropViewConfig: config.cropViewConfig, viewModel: cropViewModel)
        cropVC = CropViewController(config: config)
        cropVC.cropView = cropView
        
        TransformStack.shared.transformDelegate = cropVC
        TransformStack.shared.reset()
        XCTAssertEqual(TransformStack.shared.top, 0)
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testApplyRecords() {
        var previousState = cropView.makeCropState()
        var currentState = cropView.makeCropState()
        
        TransformStack.shared.pushTransformRecordOntoStack(transformType: .transform, 
                                                           previous: previousState,
                                                           current: currentState,
                                                           userGenerated: true)
        XCTAssertEqual(TransformStack.shared.top, 1)
        
        previousState = cropView.makeCropState()
        currentState = cropView.makeCropState()
        
        TransformStack.shared.pushTransformRecordOntoStack(transformType: .resetTransforms,
                                                           previous: previousState,
                                                           current: currentState,
                                                           userGenerated: true)
        
        XCTAssertEqual(TransformStack.shared.top, 2)
        TransformStack.shared.popTransformStack()
        XCTAssertEqual(TransformStack.shared.top, 1)
        TransformStack.shared.popTransformStack()
        XCTAssertEqual(TransformStack.shared.top, 0)
        TransformStack.shared.popTransformStack()
        XCTAssertEqual(TransformStack.shared.top, 0)
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
