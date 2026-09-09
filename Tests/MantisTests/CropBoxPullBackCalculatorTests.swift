//
//  CropBoxPullBackCalculatorTests.swift
//  MantisTests
//
//  Created by Yingtao Guo on 7/10/26.
//

import XCTest
@testable import Mantis

final class CropBoxPullBackCalculatorTests: XCTestCase {
    // A 200x200 crop box centered in a 500x500 content area, on an image
    // that extends well beyond the content bounds (zoomed in), at zoom 2
    private func makeInput(tappedEdge: CropViewAuxiliaryIndicatorHandleType,
                           desiredFrame: CGRect,
                           imageFrameInView: CGRect = CGRect(x: -300, y: -300, width: 1200, height: 1200),
                           currentZoomScale: CGFloat = 2,
                           minimumCropBoxSize: CGFloat = 42) -> CropBoxPullBackCalculator.Input {
        CropBoxPullBackCalculator.Input(tappedEdge: tappedEdge,
                                        desiredFrame: desiredFrame,
                                        cropOriginFrame: CGRect(x: 100, y: 100, width: 200, height: 200),
                                        contentBounds: CGRect(x: 0, y: 0, width: 500, height: 500),
                                        imageFrameInView: imageFrameInView,
                                        startZoomScale: 2,
                                        currentZoomScale: currentZoomScale,
                                        minimumCropBoxSize: minimumCropBoxSize)
    }

    private func assertEqual(_ result: CropBoxPullBackCalculator.Result?,
                             zoomScale: CGFloat,
                             cropBoxFrame: CGRect,
                             accuracy: CGFloat = 1e-9,
                             file: StaticString = #filePath,
                             line: UInt = #line) {
        guard let result = result else {
            XCTFail("Expected a pull back result", file: file, line: line)
            return
        }

        XCTAssertEqual(result.zoomScale, zoomScale, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(result.cropBoxFrame.minX, cropBoxFrame.minX, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(result.cropBoxFrame.minY, cropBoxFrame.minY, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(result.cropBoxFrame.width, cropBoxFrame.width, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(result.cropBoxFrame.height, cropBoxFrame.height, accuracy: accuracy, file: file, line: line)
    }

    func testNoPullBackWhenDesiredFrameFitsInContentBounds() {
        let input = makeInput(tappedEdge: .right,
                              desiredFrame: CGRect(x: 100, y: 100, width: 250, height: 200))
        XCTAssertNil(CropBoxPullBackCalculator.calculate(input))
    }

    func testNoPullBackWhenNoEdgeIsTapped() {
        let input = makeInput(tappedEdge: .none,
                              desiredFrame: CGRect(x: 100, y: 100, width: 500, height: 200))
        XCTAssertNil(CropBoxPullBackCalculator.calculate(input))
    }

    func testRightEdgeOvershootZoomsOutAnchoredAtLeftEdge() {
        // Finger wants a 500pt wide box but only 400pt is available from the
        // anchored left edge to the content bounds. The 250 image points that
        // the virtual box would cover get squeezed into 400pt: zoom 400/250
        let input = makeInput(tappedEdge: .right,
                              desiredFrame: CGRect(x: 100, y: 100, width: 500, height: 200))
        let result = CropBoxPullBackCalculator.calculate(input)

        // The vertical crop region is unchanged (100 image points), so the
        // box height shrinks with the zoom (100 * 1.6), centered vertically
        assertEqual(result,
                    zoomScale: 1.6,
                    cropBoxFrame: CGRect(x: 100, y: 120, width: 400, height: 160))
    }

    func testLeftEdgeOvershootZoomsOutAnchoredAtRightEdge() {
        let input = makeInput(tappedEdge: .left,
                              desiredFrame: CGRect(x: -300, y: 100, width: 600, height: 200),
                              imageFrameInView: CGRect(x: -500, y: -300, width: 1400, height: 1200))
        let result = CropBoxPullBackCalculator.calculate(input)

        // Available space from the anchored right edge (300) to the content
        // bounds left edge (0) is 300pt for 300 image points: zoom 1
        assertEqual(result,
                    zoomScale: 1,
                    cropBoxFrame: CGRect(x: 0, y: 150, width: 300, height: 100))
    }

    func testZoomOutStopsAtImageEdge() {
        // The image only has 300 image points from the anchor to its right
        // edge, so the crop region is capped there even though the finger
        // asks for 400: zoom 400/300
        let input = makeInput(tappedEdge: .right,
                              desiredFrame: CGRect(x: 100, y: 100, width: 800, height: 200),
                              imageFrameInView: CGRect(x: -300, y: -300, width: 1000, height: 1200))
        let result = CropBoxPullBackCalculator.calculate(input)

        let expectedZoom: CGFloat = 400.0 / 300.0
        assertEqual(result,
                    zoomScale: expectedZoom,
                    cropBoxFrame: CGRect(x: 100,
                                         y: 200 - 50 * expectedZoom,
                                         width: 400,
                                         height: 100 * expectedZoom))
    }

    func testZoomRestoresWhenFingerMovesBackInsideContentBounds() {
        // Mid pull back (current zoom 1.6), the finger moves back to a
        // position that fits: the zoom returns to the start zoom and the crop
        // box follows the finger again
        let input = makeInput(tappedEdge: .right,
                              desiredFrame: CGRect(x: 100, y: 100, width: 300, height: 200),
                              imageFrameInView: CGRect(x: -240, y: -240, width: 960, height: 960),
                              currentZoomScale: 1.6)
        let result = CropBoxPullBackCalculator.calculate(input)

        assertEqual(result,
                    zoomScale: 2,
                    cropBoxFrame: CGRect(x: 100, y: 100, width: 300, height: 200))
    }

    func testZoomOutStopsWhenPerpendicularAxisReachesMinimumCropBoxSize() {
        // The vertical box length is 100 image points * zoom; it may not
        // shrink below minimumCropBoxSize (100pt), so zoom stops at 1 even
        // though pinning the right edge would want zoom 0.5
        let input = makeInput(tappedEdge: .right,
                              desiredFrame: CGRect(x: 100, y: 100, width: 1600, height: 200),
                              imageFrameInView: CGRect(x: -300, y: -300, width: 2000, height: 1200),
                              minimumCropBoxSize: 100)
        let result = CropBoxPullBackCalculator.calculate(input)

        assertEqual(result,
                    zoomScale: 1,
                    cropBoxFrame: CGRect(x: 100, y: 150, width: 400, height: 100))
    }

    func testCornerOvershootZoomsOutAnchoredAtOppositeCorner() {
        let input = makeInput(tappedEdge: .bottomRight,
                              desiredFrame: CGRect(x: 100, y: 100, width: 500, height: 500))
        let result = CropBoxPullBackCalculator.calculate(input)

        assertEqual(result,
                    zoomScale: 1.6,
                    cropBoxFrame: CGRect(x: 100, y: 100, width: 400, height: 400))
    }

    func testAnchorPointIsOppositeToTappedEdge() {
        let frame = CGRect(x: 100, y: 100, width: 200, height: 200)

        XCTAssertEqual(CropBoxPullBackCalculator.anchorPoint(for: .right, in: frame), CGPoint(x: 100, y: 200))
        XCTAssertEqual(CropBoxPullBackCalculator.anchorPoint(for: .left, in: frame), CGPoint(x: 300, y: 200))
        XCTAssertEqual(CropBoxPullBackCalculator.anchorPoint(for: .top, in: frame), CGPoint(x: 200, y: 300))
        XCTAssertEqual(CropBoxPullBackCalculator.anchorPoint(for: .bottom, in: frame), CGPoint(x: 200, y: 100))
        XCTAssertEqual(CropBoxPullBackCalculator.anchorPoint(for: .topLeft, in: frame), CGPoint(x: 300, y: 300))
        XCTAssertEqual(CropBoxPullBackCalculator.anchorPoint(for: .topRight, in: frame), CGPoint(x: 100, y: 300))
        XCTAssertEqual(CropBoxPullBackCalculator.anchorPoint(for: .bottomLeft, in: frame), CGPoint(x: 300, y: 100))
        XCTAssertEqual(CropBoxPullBackCalculator.anchorPoint(for: .bottomRight, in: frame), CGPoint(x: 100, y: 100))
    }
}
