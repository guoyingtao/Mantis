//
//  CropViewModelTests.swift
//  MantisTests
//
//  Created by yingtguo on 1/19/23.
//

import XCTest
@testable import Mantis

final class CropViewModelTests: XCTestCase {
    
    var viewModel: CropViewModel!

    override func setUpWithError() throws {
        viewModel = CropViewModel(cropViewPadding: 20, hotAreaUnit: 20)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testClockwiseRotateBy90() {
        viewModel.rotationType = .none
        viewModel.rotateBy90(withRotateType: .clockwise)
        XCTAssertEqual(viewModel.rotationType, .counterclockwise270)
        viewModel.rotateBy90(withRotateType: .clockwise)
        XCTAssertEqual(viewModel.rotationType, .counterclockwise180)
        viewModel.rotateBy90(withRotateType: .clockwise)
        XCTAssertEqual(viewModel.rotationType, .counterclockwise90)
        viewModel.rotateBy90(withRotateType: .clockwise)
        XCTAssertEqual(viewModel.rotationType, .none)
    }
    
    func testCounterClockwiseRotateBy90() {
        viewModel.rotationType = .none
        viewModel.rotateBy90(withRotateType: .counterClockwise)
        XCTAssertEqual(viewModel.rotationType, .counterclockwise90)
        viewModel.rotateBy90(withRotateType: .counterClockwise)
        XCTAssertEqual(viewModel.rotationType, .counterclockwise180)
        viewModel.rotateBy90(withRotateType: .counterClockwise)
        XCTAssertEqual(viewModel.rotationType, .counterclockwise270)
        viewModel.rotateBy90(withRotateType: .counterClockwise)
        XCTAssertEqual(viewModel.rotationType, .none)
    }
    
    func testIsUpOrUpsideDown() {
        viewModel.rotationType = .none
        XCTAssertTrue(viewModel.isUpOrUpsideDown())
        viewModel.rotationType = .counterclockwise180
        XCTAssertTrue(viewModel.isUpOrUpsideDown())
        
        viewModel.rotationType = .counterclockwise90
        XCTAssertFalse(viewModel.isUpOrUpsideDown())
        viewModel.rotationType = .counterclockwise270
        XCTAssertFalse(viewModel.isUpOrUpsideDown())
    }
    
    func testResetCropFrame() {
        let rect = CGRect(x: 1, y: 1, width: 10, height: 10)
        viewModel.resetCropFrame(by: rect)
        
        XCTAssertEqual(viewModel.cropBoxOriginFrame, rect)
        XCTAssertEqual(viewModel.cropBoxFrame, rect)
    }
    
    func testGetTotalRadians() {
        viewModel.degrees = 31
        let radians = CGAngle(degrees: 31).radians
        viewModel.rotationType = .none
        XCTAssertEqual(viewModel.getTotalRadians(), radians)
        
        viewModel.rotationType = .counterclockwise270
        XCTAssertEqual(viewModel.getTotalRadians(), radians + CGAngle(degrees: viewModel.rotationType.rawValue).radians)
        
        viewModel.rotationType = .counterclockwise180
        XCTAssertEqual(viewModel.getTotalRadians(), radians + CGAngle(degrees: viewModel.rotationType.rawValue).radians)
        
        viewModel.rotationType = .counterclockwise90
        XCTAssertEqual(viewModel.getTotalRadians(), radians + CGAngle(degrees: viewModel.rotationType.rawValue).radians)
    }
    
    func testNeedCrop() {
        let frame = CGRect(x: 1, y: 1, width: 10, height: 10)
        viewModel.cropBoxOriginFrame = frame
        viewModel.cropBoxFrame = frame
        XCTAssertFalse(viewModel.needCrop())
        
        let frame1 = CGRect(x: 2, y: 2, width: 10, height: 10)
        viewModel.cropBoxFrame = frame1
        XCTAssertTrue(viewModel.needCrop())
    }
}
