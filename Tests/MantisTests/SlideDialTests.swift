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
        
        angle = Angle(degrees: -40)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        
        angle = Angle(degrees: 50)
        XCTAssertFalse(dial.updateRotationValue(by: angle))
        
        angle = Angle(degrees: -50)
        XCTAssertFalse(dial.updateRotationValue(by: angle))
    }
    
    func testReset() {
        var config = SlideDialConfig()
        config.limitation = 45
        setup(with: config)
        
        let angle = Angle(degrees: 40)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        
        dial.reset()
        XCTAssertEqual(viewModel.rotationAngle.degrees, 0)
        XCTAssertEqual(dial.transform, .identity)
    }

    // MARK: - updateLength

    private func setupForResizing(width: CGFloat) -> SlideDialConfig {
        var config = SlideDialConfig()
        config.limitation = 45
        viewModel = SlideDialViewModel()
        slideRuler = SlideRuler(frame: .zero, config: config)
        dial = SlideDial(frame: .zero,
                         config: config,
                         viewModel: viewModel,
                         slideRuler: slideRuler)
        dial.setupUI(withAllowableFrame: CGRect(x: 0, y: 0, width: width, height: 80))
        return config
    }

    func testUpdateLengthResizesDialAndRuler() {
        let config = setupForResizing(width: 300)

        dial.updateLength(500)

        XCTAssertEqual(dial.bounds.width, 500)
        XCTAssertEqual(slideRuler.frame, CGRect(x: 0,
                                                y: 80 - config.slideRulerHeight,
                                                width: 500,
                                                height: config.slideRulerHeight))
        XCTAssertEqual(slideRuler.scrollRulerView.contentSize.width, 1000)
        XCTAssertEqual(dial.indicator.center.x, 250)
    }

    func testUpdateLengthKeepsRotationPosition() {
        _ = setupForResizing(width: 300)
        XCTAssertTrue(dial.updateRotationValue(by: Angle(degrees: 20)))

        var reportedAngles: [Angle] = []
        dial.didUpdateRotationValue = { reportedAngles.append($0) }

        dial.updateLength(500)

        // UIScrollView rounds the content offset to the pixel grid, so allow one point.
        XCTAssertEqual(slideRuler.positionInfoHelper.getOffsetRatio(), 20.0 / 45.0, accuracy: 1 / slideRuler.offsetValue)
        XCTAssertFalse(slideRuler.centralDot.isHidden)
        // A resize is not a user scroll.
        XCTAssertTrue(reportedAngles.isEmpty)

        dial.updateLength(200)

        XCTAssertEqual(slideRuler.positionInfoHelper.getOffsetRatio(), 20.0 / 45.0, accuracy: 1 / slideRuler.offsetValue)
        XCTAssertTrue(reportedAngles.isEmpty)
    }

    func testUpdateLengthKeepsCenteredPosition() {
        _ = setupForResizing(width: 300)

        dial.updateLength(500)

        XCTAssertEqual(slideRuler.positionInfoHelper.getOffsetRatio(), 0, accuracy: 0.0001)
        XCTAssertTrue(slideRuler.centralDot.isHidden)
    }

    func testUpdateLengthIgnoresInvalidOrUnchangedLength() {
        _ = setupForResizing(width: 300)
        XCTAssertTrue(dial.updateRotationValue(by: Angle(degrees: 20)))
        let offset = slideRuler.scrollRulerView.contentOffset

        dial.updateLength(0)
        dial.updateLength(-10)
        dial.updateLength(300)

        XCTAssertEqual(dial.bounds.width, 300)
        XCTAssertEqual(slideRuler.frame.width, 300)
        XCTAssertEqual(slideRuler.scrollRulerView.contentOffset, offset)
    }
}
