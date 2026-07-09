//
//  CoreGraphicsExtensionsTests.swift
//  MantisTests
//
//  Covers the CGVector / CGRect / CGPoint helper math used by the rotation and
//  skew geometry: magnitude, normalization, dot/cross products, rotation, and
//  the signed/unsigned angle-between helpers. Also covers the NaN/infinity
//  detection getters (isBad / hasNaN).
//
//  Note: the `.checked` accessors trip an assertionFailure on bad input, so
//  these tests only feed them valid values; the bad-input paths are exercised
//  only through the non-asserting `isBad` / `hasNaN` getters.
//

import XCTest
@testable import Mantis

final class CoreGraphicsExtensionsTests: XCTestCase {

    private let accuracy: CGFloat = 1e-12

    // MARK: - isBad / hasNaN detection

    func testFloatingPointIsBad() {
        XCTAssertTrue(CGFloat.nan.isBad)
        XCTAssertTrue(CGFloat.infinity.isBad)
        XCTAssertTrue((-CGFloat.infinity).isBad)
        XCTAssertFalse(CGFloat(1.5).isBad)
        XCTAssertFalse(CGFloat(0).isBad)
    }

    func testCGSizeHasNaN() {
        XCTAssertTrue(CGSize(width: CGFloat.nan, height: 1).hasNaN)
        XCTAssertTrue(CGSize(width: 1, height: CGFloat.infinity).hasNaN)
        XCTAssertFalse(CGSize(width: 10, height: 20).hasNaN)
    }

    func testCGPointHasNaN() {
        XCTAssertTrue(CGPoint(x: CGFloat.nan, y: 0).hasNaN)
        XCTAssertFalse(CGPoint(x: 3, y: 4).hasNaN)
    }

    func testCGRectHasNaN() {
        XCTAssertTrue(CGRect(x: CGFloat.nan, y: 0, width: 1, height: 1).hasNaN)
        XCTAssertTrue(CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 1).hasNaN)
        XCTAssertFalse(CGRect(x: 0, y: 0, width: 100, height: 50).hasNaN)
    }

    func testCGVectorHasNaN() {
        XCTAssertTrue(CGVector(dx: CGFloat.nan, dy: 0).hasNaN)
        XCTAssertFalse(CGVector(dx: 1, dy: 2).hasNaN)
    }

    // MARK: - CGRect.center

    func testRectCenter() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 50)
        XCTAssertEqual(rect.center, CGPoint(x: 60, y: 45))
    }

    // MARK: - CGPoint.vector

    func testPointToVector() {
        XCTAssertEqual(CGPoint(x: 3, y: 4).vector, CGVector(dx: 3, dy: 4))
    }

    // MARK: - CGVector basics

    func testRootVector() {
        XCTAssertEqual(CGVector.root, CGVector(dx: 1, dy: 0))
    }

    func testMagnitude() {
        XCTAssertEqual(CGVector(dx: 3, dy: 4).magnitude, 5, accuracy: accuracy)
    }

    func testNormalized() {
        let unit = CGVector(dx: 3, dy: 4).normalized
        XCTAssertEqual(unit.dx, 0.6, accuracy: accuracy)
        XCTAssertEqual(unit.dy, 0.8, accuracy: accuracy)
    }

    func testVectorToPoint() {
        XCTAssertEqual(CGVector(dx: 5, dy: 6).point, CGPoint(x: 5, y: 6))
    }

    // MARK: - CGVector arithmetic

    func testDotProduct() {
        XCTAssertEqual(CGVector(dx: 1, dy: 2).dot(CGVector(dx: 3, dy: 4)), 11, accuracy: accuracy)
    }

    func testAdd() {
        XCTAssertEqual(CGVector(dx: 1, dy: 2).add(CGVector(dx: 3, dy: 4)), CGVector(dx: 4, dy: 6))
    }

    func testCrossProduct() {
        // (1,0) x (0,1) = 1; the sign encodes orientation.
        XCTAssertEqual(CGVector(dx: 1, dy: 0).cross(CGVector(dx: 0, dy: 1)), 1, accuracy: accuracy)
        XCTAssertEqual(CGVector(dx: 0, dy: 1).cross(CGVector(dx: 1, dy: 0)), -1, accuracy: accuracy)
    }

    func testScale() {
        XCTAssertEqual(CGVector(dx: 2, dy: 3).scale(2), CGVector(dx: 4, dy: 6))
    }

    // MARK: - CGVector rotation

    func testRotateQuarterTurn() {
        let rotated = CGVector(dx: 1, dy: 0).rotate(.pi / 2)
        XCTAssertEqual(rotated.dx, 0, accuracy: 1e-9)
        XCTAssertEqual(rotated.dy, 1, accuracy: 1e-9)
    }

    // MARK: - Initializers

    func testInitFromPointToPoint() {
        let vec = CGVector(fromPoint: CGPoint(x: 1, y: 1), toPoint: CGPoint(x: 4, y: 5))
        XCTAssertEqual(vec, CGVector(dx: 3, dy: 4))
    }

    func testInitFromAngleZero() {
        let vec = CGVector(angle: 0)
        XCTAssertEqual(vec.dx, 1, accuracy: 1e-9)
        XCTAssertEqual(vec.dy, 0, accuracy: 1e-9)
    }

    func testInitFromNegativeAngleWrapsIntoFullTurn() {
        // -pi/2 is normalized to 3pi/2 => (0, -1).
        let vec = CGVector(angle: -.pi / 2)
        XCTAssertEqual(vec.dx, 0, accuracy: 1e-9)
        XCTAssertEqual(vec.dy, -1, accuracy: 1e-9)
    }

    // MARK: - theta helpers

    func testThetaOfVector() {
        XCTAssertEqual(CGVector(dx: 1, dy: 0).theta, 0, accuracy: accuracy)
        XCTAssertEqual(CGVector(dx: 0, dy: 1).theta, .pi / 2, accuracy: accuracy)
    }

    func testUnsignedThetaBetweenVectorsIsAlwaysPositive() {
        let vecA = CGVector(dx: 1, dy: 0)
        let vecB = CGVector(dx: 0, dy: 1)
        XCTAssertEqual(CGVector.theta(vecA, vec2: vecB), .pi / 2, accuracy: 1e-9)
        // Order does not matter for the unsigned angle.
        XCTAssertEqual(CGVector.theta(vecB, vec2: vecA), .pi / 2, accuracy: 1e-9)
    }

    func testSignedThetaEncodesOrientation() {
        let vecA = CGVector(dx: 1, dy: 0)
        let vecB = CGVector(dx: 0, dy: 1)
        XCTAssertEqual(CGVector.signedTheta(vecA, vec2: vecB), -.pi / 2, accuracy: 1e-9)
        XCTAssertEqual(CGVector.signedTheta(vecB, vec2: vecA), .pi / 2, accuracy: 1e-9)
    }
}
