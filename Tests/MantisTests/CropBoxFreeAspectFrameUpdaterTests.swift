//
//  CropBoxFreeAspectFrameUpdaterTests.swift
//  MantisTests
//
//  Covers the free-aspect crop-box resize math: dragging one edge or corner
//  by (xDelta, yDelta) grows/shrinks the box while the opposite edge stays
//  put. Also covers the minimumAspectRatio guard that rejects a resize which
//  would make the box too thin. Pure struct math, so a sign flip here drags
//  the wrong edge or lets the box collapse.
//

import XCTest
@testable import Mantis

final class CropBoxFreeAspectFrameUpdaterTests: XCTestCase {

    // A non-square, non-origin start frame so origin and size bugs both surface.
    private let originFrame = CGRect(x: 10, y: 20, width: 100, height: 80)
    private let contentFrame = CGRect(x: 0, y: 0, width: 1000, height: 1000)

    private func makeUpdater(edge: CropViewAuxiliaryIndicatorHandleType,
                             minimumAspectRatio: CGFloat = 0) -> CropBoxFreeAspectFrameUpdater {
        var updater = CropBoxFreeAspectFrameUpdater(tappedEdge: edge,
                                                    contentFrame: contentFrame,
                                                    cropOriginFrame: originFrame,
                                                    cropBoxFrame: originFrame)
        updater.minimumAspectRatio = minimumAspectRatio
        return updater
    }

    // MARK: - Single edges

    func testRightEdgeGrowsWidthOnly() {
        var updater = makeUpdater(edge: .right)
        updater.updateCropBoxFrame(xDelta: 30, yDelta: 0)
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 10, y: 20, width: 130, height: 80))
    }

    func testLeftEdgeMovesOriginAndShrinksWidth() {
        var updater = makeUpdater(edge: .left)
        updater.updateCropBoxFrame(xDelta: 30, yDelta: 0)
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 40, y: 20, width: 70, height: 80))
    }

    func testTopEdgeMovesOriginAndShrinksHeight() {
        var updater = makeUpdater(edge: .top)
        updater.updateCropBoxFrame(xDelta: 0, yDelta: 15)
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 10, y: 35, width: 100, height: 65))
    }

    func testBottomEdgeGrowsHeightOnly() {
        var updater = makeUpdater(edge: .bottom)
        updater.updateCropBoxFrame(xDelta: 0, yDelta: 15)
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 10, y: 20, width: 100, height: 95))
    }

    // MARK: - Corners combine two edges

    func testTopLeftCornerUpdatesBothEdges() {
        var updater = makeUpdater(edge: .topLeft)
        updater.updateCropBoxFrame(xDelta: 30, yDelta: 15)
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 40, y: 35, width: 70, height: 65))
    }

    func testBottomRightCornerUpdatesBothEdges() {
        var updater = makeUpdater(edge: .bottomRight)
        updater.updateCropBoxFrame(xDelta: 30, yDelta: 15)
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 10, y: 20, width: 130, height: 95))
    }

    // MARK: - No-op edge

    func testNoneEdgeLeavesFrameUnchanged() {
        var updater = makeUpdater(edge: .none)
        updater.updateCropBoxFrame(xDelta: 30, yDelta: 15)
        XCTAssertEqual(updater.cropBoxFrame, originFrame)
    }

    // MARK: - minimumAspectRatio guard

    func testResizeRejectedWhenItWouldViolateMinimumAspectRatio() {
        // Growing width to 200 against height 80 gives ratio 0.4 (< 0.5), so the
        // update must be dropped and the frame left untouched.
        var updater = makeUpdater(edge: .right, minimumAspectRatio: 0.5)
        updater.updateCropBoxFrame(xDelta: 100, yDelta: 0)
        XCTAssertEqual(updater.cropBoxFrame, originFrame)
    }

    func testResizeAllowedWhenItStaysAboveMinimumAspectRatio() {
        // Growing width to 120 against height 80 gives ratio 0.666 (> 0.5): allowed.
        var updater = makeUpdater(edge: .right, minimumAspectRatio: 0.5)
        updater.updateCropBoxFrame(xDelta: 20, yDelta: 0)
        XCTAssertEqual(updater.cropBoxFrame, CGRect(x: 10, y: 20, width: 120, height: 80))
    }
}
