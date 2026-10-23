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
        XCTAssertEqual(cropView.getRatioType(byImageIsOriginalHorizontal: true), cropViewModel.getRatioType(byImageIsOriginalHorizontal: true))
        XCTAssertEqual(cropView.getRatioType(byImageIsOriginalHorizontal: false), cropViewModel.getRatioType(byImageIsOriginalHorizontal: false))
        XCTAssertNotEqual(cropView.getRatioType(byImageIsOriginalHorizontal: true), cropViewModel.getRatioType(byImageIsOriginalHorizontal: false))
        XCTAssertNotEqual(cropView.getRatioType(byImageIsOriginalHorizontal: false), cropViewModel.getRatioType(byImageIsOriginalHorizontal: true))
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
    
    // MARK: - Rotation control resizing
    
    // The CropView size can change without a rotation, e.g. when switching
    // between the outer and inner displays of a foldable iPhone.
    func testAdaptRotationControlResizesSlideDialWhenCropViewSizeChanges() {
        var slideDialConfig = SlideDialConfig()
        slideDialConfig.limitation = 45
        let slideRuler = SlideRuler(frame: .zero, config: slideDialConfig)
        let slideDial = SlideDial(frame: .zero,
                                  config: slideDialConfig,
                                  viewModel: SlideDialViewModel(),
                                  slideRuler: slideRuler)
        
        cropView.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        cropView.cropAuxiliaryIndicatorView.frame = CGRect(x: 20, y: 100, width: 350, height: 400)
        cropView.rotationControlView = slideDial
        cropView.setupRotationDialIfNeeded()
        
        XCTAssertEqual(slideDial.bounds.width, 390 * slideDialConfig.lengthRatio, accuracy: 0.001)
        XCTAssertEqual(slideDial.frame.midX, cropView.cropAuxiliaryIndicatorView.frame.midX, accuracy: 0.001)
        
        XCTAssertTrue(slideDial.updateRotationValue(by: Angle(degrees: 20)))
        var reportedAngles: [Angle] = []
        slideDial.didUpdateRotationValue = { reportedAngles.append($0) }
        
        // Wider than tall, so the length must come from the height.
        cropView.frame = CGRect(x: 0, y: 0, width: 820, height: 700)
        cropView.cropAuxiliaryIndicatorView.frame = CGRect(x: 60, y: 80, width: 700, height: 450)
        cropView.adaptRotationControlViewToCropBoxIfNeeded()
        
        XCTAssertEqual(slideDial.bounds.width, 700 * slideDialConfig.lengthRatio, accuracy: 0.001)
        XCTAssertEqual(slideRuler.frame.width, slideDial.bounds.width, accuracy: 0.001)
        XCTAssertEqual(slideDial.frame.midX, cropView.cropAuxiliaryIndicatorView.frame.midX, accuracy: 0.001)
        // UIScrollView rounds the content offset to the pixel grid, so allow one point.
        XCTAssertEqual(slideRuler.positionInfoHelper.getOffsetRatio(), 20.0 / 45.0, accuracy: 1 / slideRuler.offsetValue)
        // A resize is not a user scroll.
        XCTAssertTrue(reportedAngles.isEmpty)
    }
}
