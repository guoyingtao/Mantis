//
//  GeometryHelperTests.swift
//  MantisTests
//
//  Covers the crop-box boundary math: fitting a ratio rect inside another,
//  hit-testing which handle a touch lands on, and decomposing scale from an
//  affine transform. These are pure functions that drive resize / drag
//  behavior, so an off-by-one here shows up as the wrong handle activating.
//

import XCTest
@testable import Mantis

final class GeometryHelperTests: XCTestCase {

    // MARK: - getInscribeRect

    func testInscribeRectCentersInsideOutside() {
        // Same aspect ratio: the inside rect scales to exactly fill and centers.
        let outside = CGRect(x: 0, y: 0, width: 200, height: 100)
        let inside = CGRect(x: 0, y: 0, width: 20, height: 10) // ratio 2:1, same as outside
        let result = GeometryHelper.getInscribeRect(fromOutsideRect: outside, andInsideRect: inside)
        XCTAssertEqual(result, CGRect(x: 0, y: 0, width: 200, height: 100))
    }

    func testInscribeRectWiderOutsideMatchesHeight() {
        // Outside is wider than inside's ratio => height is the limiting dimension.
        let outside = CGRect(x: 0, y: 0, width: 400, height: 100)
        let inside = CGRect(x: 0, y: 0, width: 10, height: 10) // square
        let result = GeometryHelper.getInscribeRect(fromOutsideRect: outside, andInsideRect: inside)
        // Square scaled to height 100 => 100x100, centered horizontally in 400 wide.
        XCTAssertEqual(result.width, 100, accuracy: 1e-9)
        XCTAssertEqual(result.height, 100, accuracy: 1e-9)
        XCTAssertEqual(result.midX, outside.midX, accuracy: 1e-9)
        XCTAssertEqual(result.midY, outside.midY, accuracy: 1e-9)
    }

    func testInscribeRectTallerOutsideMatchesWidth() {
        // Outside is taller than inside's ratio => width is the limiting dimension.
        let outside = CGRect(x: 0, y: 0, width: 100, height: 400)
        let inside = CGRect(x: 0, y: 0, width: 10, height: 10) // square
        let result = GeometryHelper.getInscribeRect(fromOutsideRect: outside, andInsideRect: inside)
        XCTAssertEqual(result.width, 100, accuracy: 1e-9)
        XCTAssertEqual(result.height, 100, accuracy: 1e-9)
        XCTAssertEqual(result.midX, outside.midX, accuracy: 1e-9)
        XCTAssertEqual(result.midY, outside.midY, accuracy: 1e-9)
    }

    func testInscribeRectRespectsNonZeroOutsideOrigin() {
        let outside = CGRect(x: 50, y: 30, width: 200, height: 200)
        let inside = CGRect(x: 0, y: 0, width: 4, height: 2) // 2:1
        let result = GeometryHelper.getInscribeRect(fromOutsideRect: outside, andInsideRect: inside)
        // 2:1 into a 200x200 square is limited by width => 200x100, centered.
        XCTAssertEqual(result.width, 200, accuracy: 1e-9)
        XCTAssertEqual(result.height, 100, accuracy: 1e-9)
        XCTAssertEqual(result.midX, outside.midX, accuracy: 1e-9)
        XCTAssertEqual(result.midY, outside.midY, accuracy: 1e-9)
    }

    // MARK: - getCropEdge

    private let touchRect = CGRect(x: 0, y: 0, width: 100, height: 100)
    private let hotArea: CGFloat = 20

    private func edge(at point: CGPoint) -> CropViewAuxiliaryIndicatorHandleType {
        GeometryHelper.getCropEdge(forPoint: point, byTouchRect: touchRect, hotAreaUnit: hotArea)
    }

    func testCornersTakePriority() {
        XCTAssertEqual(edge(at: CGPoint(x: 5, y: 5)), .topLeft)
        XCTAssertEqual(edge(at: CGPoint(x: 95, y: 5)), .topRight)
        XCTAssertEqual(edge(at: CGPoint(x: 5, y: 95)), .bottomLeft)
        XCTAssertEqual(edge(at: CGPoint(x: 95, y: 95)), .bottomRight)
    }

    func testEdgesBetweenCorners() {
        XCTAssertEqual(edge(at: CGPoint(x: 50, y: 5)), .top)
        XCTAssertEqual(edge(at: CGPoint(x: 5, y: 50)), .left)
        XCTAssertEqual(edge(at: CGPoint(x: 95, y: 50)), .right)
        XCTAssertEqual(edge(at: CGPoint(x: 50, y: 95)), .bottom)
    }

    func testCenterHitsNoHandle() {
        XCTAssertEqual(edge(at: CGPoint(x: 50, y: 50)), .none)
    }

    func testPointOutsideTouchRectHitsNoHandle() {
        XCTAssertEqual(edge(at: CGPoint(x: 200, y: 200)), .none)
    }

    func testCornerBeatsAdjacentEdgeInOverlapZone() {
        // (15, 5) lies in both the top-left corner rect and the top edge rect;
        // the corner must win because it is tested first.
        XCTAssertEqual(edge(at: CGPoint(x: 15, y: 5)), .topLeft)
    }

    // MARK: - scale(from:)

    func testScaleFromIdentityIsOne() {
        XCTAssertEqual(GeometryHelper.scale(from: .identity), 1.0, accuracy: 1e-12)
    }

    func testScaleFromUniformScaleTransform() {
        let transform = CGAffineTransform(scaleX: 3, y: 3)
        XCTAssertEqual(GeometryHelper.scale(from: transform), 3.0, accuracy: 1e-12)
    }

    func testScaleIsRotationInvariant() {
        // sqrt(a^2 + c^2) recovers the scale magnitude regardless of rotation.
        let transform = CGAffineTransform(scaleX: 2, y: 2).rotated(by: .pi / 3)
        XCTAssertEqual(GeometryHelper.scale(from: transform), 2.0, accuracy: 1e-12)
    }

    func testScaleFromPureRotationIsOne() {
        let transform = CGAffineTransform(rotationAngle: .pi / 4)
        XCTAssertEqual(GeometryHelper.scale(from: transform), 1.0, accuracy: 1e-12)
    }
}
