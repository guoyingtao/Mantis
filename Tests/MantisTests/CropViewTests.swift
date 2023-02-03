//
//  CropViewTests.swift
//  MantisTests
//
//  Created by yingtguo on 2/3/23.
//

import XCTest
@testable import Mantis

final class CropViewTests: XCTestCase {
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
        cropView = createCropView(viewModel: cropViewModel)
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGetTotalRadians() {
        cropViewModel.degrees = Angle(degrees: 30).degrees
        cropView = createCropView(viewModel: cropViewModel)

        print(cropView.getTotalRadians())
        XCTAssertEqual(cropView.getTotalRadians(), cropViewModel.getTotalRadians())
    }
    
    func testGetRatioType() {
        XCTAssertEqual(cropView.getRatioType(byImageIsOriginalisHorizontal: true), cropViewModel.getRatioType(byImageIsOriginalHorizontal: true))
        XCTAssertEqual(cropView.getRatioType(byImageIsOriginalisHorizontal: false), cropViewModel.getRatioType(byImageIsOriginalHorizontal: false))
        XCTAssertNotEqual(cropView.getRatioType(byImageIsOriginalisHorizontal: true), cropViewModel.getRatioType(byImageIsOriginalHorizontal: false))
        XCTAssertNotEqual(cropView.getRatioType(byImageIsOriginalisHorizontal: false), cropViewModel.getRatioType(byImageIsOriginalHorizontal: true))
    }
    
    private func testGetImageHorizontalToVerticalRatioWithUpDownAndMirror(testImage: UIImage) {
        cropViewModel.rotationType = .none
        cropView = createCropView(with: testImage, viewModel: cropViewModel)
        XCTAssertEqual(cropView.getImageHorizontalToVerticalRatio(), Double(testImage.size.width / testImage.size.height))

        cropViewModel.rotationType = .counterclockwise180
        cropView = createCropView(with: testImage, viewModel: cropViewModel)
        XCTAssertEqual(cropView.getImageHorizontalToVerticalRatio(), Double(testImage.size.width / testImage.size.height))
        
        cropViewModel.rotationType = .counterclockwise90
        cropView = createCropView(with: testImage, viewModel: cropViewModel)
        XCTAssertEqual(cropView.getImageHorizontalToVerticalRatio(), Double(testImage.size.height / testImage.size.width))
        
        cropViewModel.rotationType = .counterclockwise270
        cropView = createCropView(with: testImage, viewModel: cropViewModel)
        XCTAssertEqual(cropView.getImageHorizontalToVerticalRatio(), Double(testImage.size.height / testImage.size.width))
    }
    
    private func testGetImageHorizontalToVerticalRatioWithLeftRightAndMirror(testImage: UIImage) {
        cropViewModel.rotationType = .none
        cropView = createCropView(with: testImage, viewModel: cropViewModel)
        XCTAssertEqual(cropView.getImageHorizontalToVerticalRatio(), Double(testImage.size.height / testImage.size.width))

        cropViewModel.rotationType = .counterclockwise180
        cropView = createCropView(with: testImage, viewModel: cropViewModel)
        XCTAssertEqual(cropView.getImageHorizontalToVerticalRatio(), Double(testImage.size.height / testImage.size.width))
        
        cropViewModel.rotationType = .counterclockwise90
        cropView = createCropView(with: testImage, viewModel: cropViewModel)
        XCTAssertEqual(cropView.getImageHorizontalToVerticalRatio(), Double(testImage.size.width / testImage.size.height))
        
        cropViewModel.rotationType = .counterclockwise270
        cropView = createCropView(with: testImage, viewModel: cropViewModel)
        XCTAssertEqual(cropView.getImageHorizontalToVerticalRatio(), Double(testImage.size.width / testImage.size.height))
    }
    
    func testGetImageHorizontalToVerticalRatio() {
        let testImage = TestHelper.createATestImage(bySize: .init(width: 200, height: 50))
        testGetImageHorizontalToVerticalRatioWithUpDownAndMirror(testImage: testImage)
        
        let downOrientationImage = UIImage(cgImage: testImage.cgImage!, scale: testImage.scale, orientation: .down)
        testGetImageHorizontalToVerticalRatioWithUpDownAndMirror(testImage: downOrientationImage)
        
        let upMirroredOrientationImage = UIImage(cgImage: testImage.cgImage!, scale: testImage.scale, orientation: .upMirrored)
        testGetImageHorizontalToVerticalRatioWithUpDownAndMirror(testImage: upMirroredOrientationImage)
        
        let downMirroredOrientationImage = UIImage(cgImage: testImage.cgImage!, scale: testImage.scale, orientation: .downMirrored)
        testGetImageHorizontalToVerticalRatioWithUpDownAndMirror(testImage: downMirroredOrientationImage)
                
        let leftOrientationImage = UIImage(cgImage: testImage.cgImage!, scale: testImage.scale, orientation: .left)
        testGetImageHorizontalToVerticalRatioWithLeftRightAndMirror(testImage: leftOrientationImage)
        
        let leftMirroredOrientationImage = UIImage(cgImage: testImage.cgImage!, scale: testImage.scale, orientation: .leftMirrored)
        testGetImageHorizontalToVerticalRatioWithLeftRightAndMirror(testImage: leftMirroredOrientationImage)

        let rightOrientationImage = UIImage(cgImage: testImage.cgImage!, scale: testImage.scale, orientation: .right)
        testGetImageHorizontalToVerticalRatioWithLeftRightAndMirror(testImage: rightOrientationImage)
        
        let rightMirroredOrientationImage = UIImage(cgImage: testImage.cgImage!, scale: testImage.scale, orientation: .rightMirrored)
        testGetImageHorizontalToVerticalRatioWithLeftRightAndMirror(testImage: rightMirroredOrientationImage)
    }
}
