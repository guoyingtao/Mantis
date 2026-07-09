//
//  SlideRulerPositionHelperTests.swift
//  MantisTests
//
//  Covers the two SlideRulerPositionHelper strategies that map between the
//  rotation ruler's scroll offset and a normalized progress ratio. The
//  bilateral variant is centered (ratio in [-1, 1]); the unilateral variant
//  starts at one end (ratio in [0, 1]). Both clamp out-of-range offsets, and
//  getRulerOffsetX / setOffset are inverse-ish mappings the dial depends on.
//

import XCTest
@testable import Mantis

final class SlideRulerPositionHelperTests: XCTestCase {

    private let accuracy: CGFloat = 1e-9

    /// A ruler laid out at width 200. Assigning `bounds` after init triggers
    /// the `bounds` didSet -> setUIFrames(), which lays out the inner
    /// scrollRulerView (frame = bounds) and sets offsetValue = 0.5 * 200 = 100.
    /// (The observer does not fire for the frame passed to init, so we set it
    /// explicitly here to force the layout the helpers read from.)
    private func makeRuler() -> SlideRuler {
        let ruler = SlideRuler(frame: CGRect(x: 0, y: 0, width: 200, height: 40),
                               config: SlideDialConfig())
        ruler.bounds = CGRect(x: 0, y: 0, width: 200, height: 40)
        return ruler
    }

    // MARK: - Bilateral (centered) strategy

    private func makeBilateral() -> (BilateralTypeSlideRulerPositionHelper, SlideRuler) {
        let helper = BilateralTypeSlideRulerPositionHelper()
        let ruler = makeRuler()
        helper.slideRuler = ruler
        return (helper, ruler)
    }

    func testBilateralConstants() {
        let (helper, _) = makeBilateral()
        XCTAssertEqual(helper.getInitialOffsetRatio(), 0.5, accuracy: accuracy)
        XCTAssertEqual(helper.getForceAlignCenterX(), 100, accuracy: accuracy) // frame.width / 2
        XCTAssertEqual(helper.getCentralDotCenterX(), 200, accuracy: accuracy) // frame.width
    }

    func testBilateralRulerOffsetX() {
        let (helper, _) = makeBilateral()
        // progress * offsetValue + offsetValue, offsetValue = 100.
        XCTAssertEqual(helper.getRulerOffsetX(with: 0), 100, accuracy: accuracy)
        XCTAssertEqual(helper.getRulerOffsetX(with: 0.5), 150, accuracy: accuracy)
        XCTAssertEqual(helper.getRulerOffsetX(with: -1), 0, accuracy: accuracy)
    }

    func testBilateralOffsetRatioIsCenteredAndClamped() {
        let (helper, ruler) = makeBilateral()
        // (contentOffset.x - offsetValue) / offsetValue, offsetValue = 100.
        ruler.scrollRulerView.contentOffset = CGPoint(x: 150, y: 0)
        XCTAssertEqual(helper.getOffsetRatio(), 0.5, accuracy: accuracy)
        ruler.scrollRulerView.contentOffset = CGPoint(x: 100, y: 0)
        XCTAssertEqual(helper.getOffsetRatio(), 0, accuracy: accuracy)
        // Beyond the ends clamps to +/-1.
        ruler.scrollRulerView.contentOffset = CGPoint(x: 1000, y: 0)
        XCTAssertEqual(helper.getOffsetRatio(), 1, accuracy: accuracy)
        ruler.scrollRulerView.contentOffset = CGPoint(x: -1000, y: 0)
        XCTAssertEqual(helper.getOffsetRatio(), -1, accuracy: accuracy)
    }

    func testBilateralOffsetRatioGuardsZeroOffsetValue() {
        let (helper, ruler) = makeBilateral()
        ruler.offsetValue = 0
        ruler.scrollRulerView.contentOffset = CGPoint(x: 50, y: 0)
        XCTAssertEqual(helper.getOffsetRatio(), 0, accuracy: accuracy)
    }

    func testBilateralSetOffset() {
        let (helper, ruler) = makeBilateral()
        // offsetX = offsetRatio * (frame.width/2) + frame.width/2, width = 200.
        helper.setOffset(offsetRatio: 0.5)
        XCTAssertEqual(ruler.scrollRulerView.contentOffset.x, 150, accuracy: accuracy)
        helper.setOffset(offsetRatio: -1)
        XCTAssertEqual(ruler.scrollRulerView.contentOffset.x, 0, accuracy: accuracy)
    }

    func testBilateralCheckIsCenterPosition() {
        let (helper, ruler) = makeBilateral()
        // abs(contentOffset.x - frame.width/2) < limit, center at 100.
        ruler.scrollRulerView.contentOffset = CGPoint(x: 100, y: 0)
        XCTAssertTrue(helper.checkIsCenterPosition(with: 1))
        ruler.scrollRulerView.contentOffset = CGPoint(x: 150, y: 0)
        XCTAssertFalse(helper.checkIsCenterPosition(with: 10))
    }

    // MARK: - Unilateral (one-sided) strategy

    private func makeUnilateral() -> (UnilateralTypeSlideRulerPositionHelper, SlideRuler) {
        let helper = UnilateralTypeSlideRulerPositionHelper()
        let ruler = makeRuler()
        helper.slideRuler = ruler
        return (helper, ruler)
    }

    func testUnilateralConstants() {
        let (helper, _) = makeUnilateral()
        XCTAssertEqual(helper.getInitialOffsetRatio(), 0, accuracy: accuracy)
        XCTAssertEqual(helper.getForceAlignCenterX(), 0, accuracy: accuracy)
    }

    func testUnilateralRulerOffsetX() {
        let (helper, _) = makeUnilateral()
        // progress * scrollRulerView.frame.width, width = 200.
        XCTAssertEqual(helper.getRulerOffsetX(with: 0.5), 100, accuracy: accuracy)
        XCTAssertEqual(helper.getRulerOffsetX(with: 1), 200, accuracy: accuracy)
    }

    func testUnilateralOffsetRatioIsClampedToUnitRange() {
        let (helper, ruler) = makeUnilateral()
        // contentOffset.x / bounds.width, bounds.width = 200.
        ruler.scrollRulerView.contentOffset = CGPoint(x: 100, y: 0)
        XCTAssertEqual(helper.getOffsetRatio(), 0.5, accuracy: accuracy)
        ruler.scrollRulerView.contentOffset = CGPoint(x: 400, y: 0)
        XCTAssertEqual(helper.getOffsetRatio(), 1, accuracy: accuracy)
        ruler.scrollRulerView.contentOffset = CGPoint(x: -50, y: 0)
        XCTAssertEqual(helper.getOffsetRatio(), 0, accuracy: accuracy)
    }

    func testUnilateralSetOffset() {
        let (helper, ruler) = makeUnilateral()
        // offsetRatio * scrollRulerView.frame.width / 2, width = 200.
        helper.setOffset(offsetRatio: 0.5)
        XCTAssertEqual(ruler.scrollRulerView.contentOffset.x, 50, accuracy: accuracy)
    }

    func testUnilateralCheckIsCenterPosition() {
        let (helper, ruler) = makeUnilateral()
        // abs(contentOffset.x) < limit.
        ruler.scrollRulerView.contentOffset = CGPoint(x: 0, y: 0)
        XCTAssertTrue(helper.checkIsCenterPosition(with: 1))
        ruler.scrollRulerView.contentOffset = CGPoint(x: 50, y: 0)
        XCTAssertFalse(helper.checkIsCenterPosition(with: 10))
    }
}
