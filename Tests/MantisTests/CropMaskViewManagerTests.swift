//
//  CropMaskViewManagerTests.swift
//  MantisTests
//
//  Created by yingtguo on 2/5/23.
//

import XCTest
@testable import Mantis

final class CropMaskViewManagerTests: XCTestCase {
    
    var cropMaskViewManager: CropMaskViewManager!
    let dimmingView = FakeCropMaskView(frame: .zero)
    let visualEffectView = FakeCropMaskView(frame: .zero)
    
    override func setUpWithError() throws {
        cropMaskViewManager = CropMaskViewManager(dimmingView: dimmingView, visualEffectView: visualEffectView)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSetup() {
        XCTAssertEqual(cropMaskViewManager.maskViews.count, 2)
        let container = UIView()
        cropMaskViewManager.setup(in: container)
        XCTAssertEqual(dimmingView.alpha, 0)
        XCTAssertEqual(visualEffectView.alpha, 1)
        
        cropMaskViewManager.maskViews.forEach { maskView in
            XCTAssertEqual(maskView.superview, container)
        }
    }
    
    func testRemoveMaskViews() {
        cropMaskViewManager.removeMaskViews()
        XCTAssertEqual(cropMaskViewManager.maskViews.count, 2)
     
        cropMaskViewManager.maskViews.forEach { maskView in
            XCTAssertNil(maskView.superview)
        }
    }
    
    func testShowDimmingBackground() {
        dimmingView.alpha = 0
        visualEffectView.alpha = 1
        cropMaskViewManager.showDimmingBackground(animated: false)
        XCTAssertEqual(dimmingView.alpha, 1)
        XCTAssertEqual(visualEffectView.alpha, 0)
        
        dimmingView.alpha = 0
        visualEffectView.alpha = 1
        cropMaskViewManager.showDimmingBackground(animated: true)
        XCTAssertEqual(dimmingView.alpha, 1)
        XCTAssertEqual(visualEffectView.alpha, 0)
    }
    
    func testShowVisualEffectBackground() {
        dimmingView.alpha = 1
        visualEffectView.alpha = 0
        cropMaskViewManager.showVisualEffectBackground(animated: false)
        XCTAssertEqual(dimmingView.alpha, 0)
        XCTAssertEqual(visualEffectView.alpha, 1)
        
        dimmingView.alpha = 1
        visualEffectView.alpha = 0
        cropMaskViewManager.showVisualEffectBackground(animated: true)
        XCTAssertEqual(dimmingView.alpha, 0)
        XCTAssertEqual(visualEffectView.alpha, 1)
    }
}
