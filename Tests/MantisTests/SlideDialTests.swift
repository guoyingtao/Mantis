//
//  SlideDialTests.swift
//  MantisTests
//
//  Created by Yingtao Guo on 6/20/23.
//

import XCTest
@testable import Mantis

final class SlideDialTests: XCTestCase {
    
    var dial: SlideDial!
    var slideRuler: SlideRuler!
    var viewModel: SlideDialViewModel!

    override func setUpWithError() throws {
        let config = SlideDialConfig()
        setup(with: config)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    private func setup(with config: SlideDialConfig) {
        viewModel = SlideDialViewModel()
        slideRuler = SlideRuler(frame: .zero, config: config)
        dial = SlideDial(frame: .zero,
                         config: config,
                         viewModel: viewModel,
                         slideRuler: slideRuler)
        dial.setupUI(withAllowableFrame: .zero)
    }
    
    func testSlidingSlideDial() {
        var config = SlideDialConfig()
        config.limitation = 45
        setup(with: config)
        
        var angle = Angle(degrees: 40)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        XCTAssertEqual(viewModel.rotationAngle.degrees, 40)
        
        angle = Angle(degrees: -40)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        XCTAssertEqual(viewModel.rotationAngle.degrees, -40)
        
        angle = Angle(degrees: 50)
        XCTAssertFalse(dial.updateRotationValue(by: angle))
        XCTAssertEqual(viewModel.rotationAngle.degrees, 45)
        
        angle = Angle(degrees: -50)
        XCTAssertFalse(dial.updateRotationValue(by: angle))
        XCTAssertEqual(viewModel.rotationAngle.degrees, -45)
    }
    
    func testReset() {
        var config = SlideDialConfig()
        config.limitation = 45
        setup(with: config)
        
        let angle = Angle(degrees: 40)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        XCTAssertEqual(viewModel.rotationAngle.degrees, 40)
        
        dial.reset()
        XCTAssertEqual(viewModel.rotationAngle.degrees, 0)
        XCTAssertEqual(dial.transform, .identity)
    }
}
