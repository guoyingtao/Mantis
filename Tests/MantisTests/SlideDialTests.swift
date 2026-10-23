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

    private func setupForResizing(width: CGFloat,
                                  height: CGFloat = 80,
                                  mode: SlideDialMode = .simple) -> SlideDialConfig {
        var config = SlideDialConfig()
        config.limitation = 45
        config.mode = mode
        viewModel = SlideDialViewModel()
        slideRuler = SlideRuler(frame: .zero, config: config)
        dial = SlideDial(frame: .zero,
                         config: config,
                         viewModel: viewModel,
                         slideRuler: slideRuler)
        dial.setupUI(withAllowableFrame: CGRect(x: 0, y: 0, width: width, height: height))
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

    func testUpdateLengthResizesTypeSelectorDial() throws {
        let config = setupForResizing(width: 300, height: 120, mode: .withTypeSelector)

        dial.updateLength(500)

        XCTAssertEqual(dial.bounds.width, 500)
        XCTAssertEqual(slideRuler.frame, CGRect(x: 0,
                                                y: 120 - config.slideRulerHeight,
                                                width: 500,
                                                height: config.slideRulerHeight))
        // The selected button stays centered above the ruler pointer.
        XCTAssertEqual(try XCTUnwrap(dial.typeButtons[.straighten]).frame.midX, 250, accuracy: 0.001)
    }

    func testUpdateLengthKeepsRotationPosition() {
        for degrees: CGFloat in [-44, -20, 20, 44] {
            _ = setupForResizing(width: 300)
            XCTAssertTrue(dial.updateRotationValue(by: Angle(degrees: degrees)))
            let expectedRatio = degrees / 45.0

            var reportedAngles: [Angle] = []
            dial.didUpdateRotationValue = { reportedAngles.append($0) }

            dial.updateLength(500)

            // UIScrollView rounds the content offset to the pixel grid, so allow one point.
            XCTAssertEqual(slideRuler.positionInfoHelper.getOffsetRatio(), expectedRatio,
                           accuracy: 1 / slideRuler.offsetValue, "\(degrees)°")
            XCTAssertFalse(slideRuler.centralDot.isHidden, "\(degrees)°")
            // A resize is not a user scroll.
            XCTAssertTrue(reportedAngles.isEmpty, "\(degrees)°")

            dial.updateLength(200)

            XCTAssertEqual(slideRuler.positionInfoHelper.getOffsetRatio(), expectedRatio,
                           accuracy: 1 / slideRuler.offsetValue, "\(degrees)°")
            XCTAssertTrue(reportedAngles.isEmpty, "\(degrees)°")
        }
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
        // A resize would show the central dot at 20°, so this tells whether one ran.
        slideRuler.centralDot.isHidden = true

        dial.updateLength(0)
        dial.updateLength(-10)
        dial.updateLength(300)

        XCTAssertEqual(dial.bounds.width, 300)
        XCTAssertEqual(slideRuler.frame.width, 300)
        XCTAssertEqual(slideRuler.scrollRulerView.contentOffset, offset)
        XCTAssertTrue(slideRuler.centralDot.isHidden)
    }
}
