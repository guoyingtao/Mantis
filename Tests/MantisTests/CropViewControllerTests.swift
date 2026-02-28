//
//  CropViewControllerTests.swift
//  MantisTests
//
//  Created by yingtguo on 2/2/23.
//

import XCTest
@testable import Mantis

final class CropViewControllerTests: XCTestCase {
    
    let cropVC = CropViewController()
    let fakeCropView = FakeCropView()
    let fakeCropToolbar = FakeCropToolbar()
    let fakeCropVCDelegate = FakeCropViewControllerDelegate()

    override func setUpWithError() throws {
        cropVC.cropView = fakeCropView
        cropVC.cropToolbar = fakeCropToolbar
        cropVC.delegate = fakeCropVCDelegate
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCropViewDidBecomeResettable() {
        XCTAssertFalse(fakeCropToolbar.didHandleCropViewDidBecomeResettable)
        XCTAssertFalse(fakeCropVCDelegate.didImageTransformed)
        
        cropVC.cropViewDidBecomeResettable(cropVC.cropView)

        XCTAssertTrue(fakeCropToolbar.didHandleCropViewDidBecomeResettable)
        XCTAssertTrue(fakeCropVCDelegate.didImageTransformed)
    }
    
    func testCropViewDidBecomeUnResettable() {
        XCTAssertFalse(fakeCropToolbar.didHandleCropViewDidBecomeUnResettable)
        
        cropVC.cropViewDidBecomeUnResettable(cropVC.cropView)
        
        XCTAssertTrue(fakeCropToolbar.didHandleCropViewDidBecomeUnResettable)
    }
    
    func testCropViewDidBeginResize() {
        XCTAssertFalse(fakeCropVCDelegate.didBeginResize)
        
        cropVC.cropViewDidBeginResize(cropVC.cropView)
        
        XCTAssertTrue(fakeCropVCDelegate.didBeginResize)
    }
    
    func testCropViewDidEndResize() {
        XCTAssertFalse(fakeCropVCDelegate.didEndResize)
        
        cropVC.cropViewDidEndResize(cropVC.cropView)
        
        XCTAssertTrue(fakeCropVCDelegate.didEndResize)
    }
    
    func testCropViewDidBeginCrop() {
        XCTAssertFalse(fakeCropVCDelegate.didBeginCrop)
        
        cropVC.cropViewDidBeginCrop(cropVC.cropView)
        
        XCTAssertTrue(fakeCropVCDelegate.didBeginCrop)
    }
    
    func testCropViewDidEndCrop() {
        XCTAssertFalse(fakeCropVCDelegate.didEndCrop)
        
        cropVC.cropViewDidEndCrop(cropVC.cropView)
        
        XCTAssertTrue(fakeCropVCDelegate.didEndCrop)
    }
}
