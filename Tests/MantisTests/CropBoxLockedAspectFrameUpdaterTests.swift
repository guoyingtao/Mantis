//
//  CropBoxLockedAspectFrameUpdaterTests.swift
//  MantisTests
//
//  Characterizes the fixed-aspect crop-box resize math: dragging an edge or
//  corner must keep the box's aspect ratio locked. These are the exact frames
//  the current implementation produces; they pin the behavior so a refactor
//  that changes the geometry has to be a deliberate choice, not a silent
//  regression. Side edges recompute height from width (and vice versa); corners
//  use a scale factor with ceil() rounding.
//

import XCTest
@testable import Mantis

final class CropBoxLockedAspectFrameUpdaterTests: XCTestCase {

    private let contentFrame = CGRect(x: 0, y: 0, width: 1000, height: 1000)

    private func makeUpdater(edge: CropViewAuxiliaryIndicatorHandleType,
                             originFrame: CGRect) -> CropBoxLockedAspectFrameUpdater {
        CropBoxLockedAspectFrameUpdater(tappedEdge: edge,
                                        contentFrame: contentFrame,
                                        cropOriginFrame: originFrame,
                                        cropBoxFrame: originFrame)
    }

    // MARK: - Side edges keep the 1:1 ratio (square start frame)

    private let square = CGRect(x: 0, y: 0, width: 100, height: 100)

    func testRightEdgeGrowsAndKeepsSquare() {
        var updater = makeUpdater(edge: .right, originFrame: square)
        updater.updateCropBoxFrame(xDelta: 20, yDelta: 0)
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 0, y: 0, width: 120, height: 120))
    }

    func testLeftEdgeShrinksAndKeepsSquare() {
        var updater = makeUpdater(edge: .left, originFrame: square)
        updater.updateCropBoxFrame(xDelta: 20, yDelta: 0)
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 20, y: 0, width: 80, height: 80))
    }

    func testTopEdgeShrinksAndKeepsSquare() {
        var updater = makeUpdater(edge: .top, originFrame: square)
        updater.updateCropBoxFrame(xDelta: 0, yDelta: 20)
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 0, y: 20, width: 80, height: 80))
    }

    func testBottomEdgeGrowsAndKeepsSquare() {
        var updater = makeUpdater(edge: .bottom, originFrame: square)
        updater.updateCropBoxFrame(xDelta: 0, yDelta: 20)
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 0, y: 0, width: 120, height: 120))
    }

    // MARK: - Side edge with a non-square ratio (2:1)

    func testRightEdgeKeepsTwoToOneRatio() {
        let wide = CGRect(x: 0, y: 0, width: 200, height: 100) // aspectRatio 2
        var updater = makeUpdater(edge: .right, originFrame: wide)
        updater.updateCropBoxFrame(xDelta: 40, yDelta: 0)
        // width 200+40=240; height 240/2=120; box grows down from y=0.
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 0, y: 0, width: 240, height: 120))
    }

    // MARK: - Corners use a scale factor with ceil() rounding

    func testBottomRightCornerScalesFromTopLeftAnchor() {
        var updater = makeUpdater(edge: .bottomRight, originFrame: square)
        updater.updateCropBoxFrame(xDelta: 20, yDelta: 20)
        // scale = ((1+0.2)+(1+0.2))/2 = 1.2 => 120x120, origin unchanged.
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 0, y: 0, width: 120, height: 120))
    }

    func testTopLeftCornerScalesFromBottomRightAnchor() {
        var updater = makeUpdater(edge: .topLeft, originFrame: square)
        updater.updateCropBoxFrame(xDelta: 20, yDelta: 20)
        // scale = ((1-0.2)+(1-0.2))/2 = 0.8 => 80x80; origin shifts by (100-80).
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 20, y: 20, width: 80, height: 80))
    }

    func testBottomLeftCornerPinsRightEdge() {
        var updater = makeUpdater(edge: .bottomLeft, originFrame: square)
        updater.updateCropBoxFrame(xDelta: 20, yDelta: -20)
        // rule .bottomLeft = (xDelta, -yDelta) = (20, 20); scale 0.8 => 80x80.
        // origin.x = maxX(100) - width(80) = 20; origin.y stays 0.
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 20, y: 0, width: 80, height: 80))
    }

    func testCeilRoundingProducesIntegralSize() {
        // scale that lands on a fraction must be rounded up by ceil().
        var updater = makeUpdater(edge: .bottomRight, originFrame: square)
        updater.updateCropBoxFrame(xDelta: 5, yDelta: 0)
        // distance.x = 1+0.05, distance.y = 1 => scale 1.025 => 102.5 -> ceil 103.
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 0, y: 0, width: 103, height: 103))
    }

    // MARK: - No-op edge

    func testNoneEdgeLeavesFrameUnchanged() {
        var updater = makeUpdater(edge: .none, originFrame: square)
        updater.updateCropBoxFrame(xDelta: 20, yDelta: 20)
        XCTAssertEqual(updater.cropBoxFrame, square)
    }
}
