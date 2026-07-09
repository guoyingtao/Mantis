//
//  RotationCalculatorTests.swift
//  MantisTests
//
//  Covers the polar math behind the rotation dial gesture: mapping a touch
//  point to an absolute angle around a midpoint, and turning an old/new point
//  pair into a relative rotation wrapped into (-pi, pi]. An error here shows up
//  as the dial jumping or spinning the wrong way when a drag crosses the
//  ±180° seam.
//

import XCTest
@testable import Mantis

final class RotationCalculatorTests: XCTestCase {

    private let accuracy: CGFloat = 1e-6

    private func makeCalculator() -> RotationCalculator {
        // Midpoint at the origin keeps the expected angles easy to reason about.
        RotationCalculator(midPoint: .zero)
    }

    // MARK: - Fresh state

    func testFreshCalculatorHasNoRotationAngleOrDistance() {
        let calculator = makeCalculator()
        XCTAssertNil(calculator.rotation)
        XCTAssertNil(calculator.angle)
        XCTAssertNil(calculator.distance)
    }

    // MARK: - Absolute angle mapping
    //
    // The mapping is: +x axis -> 0, +y axis -> pi/2, -x axis -> pi,
    // -y axis -> 3pi/2 (angles are normalized into [0, 2pi)).

    func testAngleAlongPositiveXAxisIsZeroModuloTwoPi() {
        // The +x axis sits exactly on the 0 / 2pi seam. Float rounding in the
        // atan2 path can land the result infinitesimally below 0, which the
        // normalization then wraps up to ~2pi. Both are the same angle, so
        // compare modulo 2pi rather than to a bare 0.
        let calculator = makeCalculator()
        _ = calculator.getRotationRadians(byOldPoint: .zero, andNewPoint: CGPoint(x: 1, y: 0))
        let angle = calculator.angle ?? .nan
        let distanceToSeam = min(angle, abs(.pi * 2 - angle))
        XCTAssertEqual(distanceToSeam, 0, accuracy: accuracy)
    }

    func testAngleAlongPositiveYAxisIsHalfPi() {
        let calculator = makeCalculator()
        _ = calculator.getRotationRadians(byOldPoint: .zero, andNewPoint: CGPoint(x: 0, y: 1))
        XCTAssertEqual(calculator.angle ?? .nan, .pi / 2, accuracy: accuracy)
    }

    func testAngleAlongNegativeXAxisIsPi() {
        let calculator = makeCalculator()
        _ = calculator.getRotationRadians(byOldPoint: .zero, andNewPoint: CGPoint(x: -1, y: 0))
        XCTAssertEqual(calculator.angle ?? .nan, .pi, accuracy: accuracy)
    }

    func testAngleAlongNegativeYAxisWrapsToThreeHalfPi() {
        // Raw angle is -pi/2; the calculator adds 2pi to keep it in [0, 2pi).
        let calculator = makeCalculator()
        _ = calculator.getRotationRadians(byOldPoint: .zero, andNewPoint: CGPoint(x: 0, y: -1))
        XCTAssertEqual(calculator.angle ?? .nan, .pi * 3 / 2, accuracy: accuracy)
    }

    // MARK: - Relative rotation

    func testCounterClockwiseQuarterTurn() {
        // +x (angle 0) -> +y (angle pi/2) is +pi/2.
        let calculator = makeCalculator()
        let rotation = calculator.getRotationRadians(byOldPoint: CGPoint(x: 1, y: 0),
                                                     andNewPoint: CGPoint(x: 0, y: 1))
        XCTAssertEqual(rotation, .pi / 2, accuracy: accuracy)
    }

    func testClockwiseQuarterTurn() {
        // +y (angle pi/2) -> +x (angle 0) is -pi/2.
        let calculator = makeCalculator()
        let rotation = calculator.getRotationRadians(byOldPoint: CGPoint(x: 0, y: 1),
                                                     andNewPoint: CGPoint(x: 1, y: 0))
        XCTAssertEqual(rotation, -.pi / 2, accuracy: accuracy)
    }

    func testRotationWrapsWhenCrossingSeamPositive() {
        // 0 -> 3pi/2 raw is +3pi/2 (> pi), so it wraps to the short way: -pi/2.
        let calculator = makeCalculator()
        let rotation = calculator.getRotationRadians(byOldPoint: CGPoint(x: 1, y: 0),
                                                     andNewPoint: CGPoint(x: 0, y: -1))
        XCTAssertEqual(rotation, -.pi / 2, accuracy: accuracy)
    }

    func testRotationWrapsWhenCrossingSeamNegative() {
        // 3pi/2 -> 0 raw is -3pi/2 (< -pi), so it wraps to the short way: +pi/2.
        let calculator = makeCalculator()
        let rotation = calculator.getRotationRadians(byOldPoint: CGPoint(x: 0, y: -1),
                                                     andNewPoint: CGPoint(x: 1, y: 0))
        XCTAssertEqual(rotation, .pi / 2, accuracy: accuracy)
    }

    func testNoMovementYieldsZeroRotation() {
        let calculator = makeCalculator()
        let rotation = calculator.getRotationRadians(byOldPoint: CGPoint(x: 1, y: 1),
                                                     andNewPoint: CGPoint(x: 1, y: 1))
        XCTAssertEqual(rotation, 0, accuracy: accuracy)
    }

    // MARK: - Distance

    func testDistanceFromMidpoint() {
        let calculator = makeCalculator()
        _ = calculator.getRotationRadians(byOldPoint: .zero, andNewPoint: CGPoint(x: 3, y: 4))
        XCTAssertEqual(calculator.distance ?? .nan, 5, accuracy: accuracy)
    }

    func testDistanceRespectsNonZeroMidpoint() {
        let calculator = RotationCalculator(midPoint: CGPoint(x: 10, y: 10))
        _ = calculator.getRotationRadians(byOldPoint: .zero, andNewPoint: CGPoint(x: 13, y: 14))
        XCTAssertEqual(calculator.distance ?? .nan, 5, accuracy: accuracy)
    }

    // MARK: - Midpoint offset invariance

    func testRotationIsInvariantToMidpointTranslation() {
        // Translating both points and the midpoint by the same offset must not
        // change the measured rotation.
        let base = makeCalculator()
        let baseRotation = base.getRotationRadians(byOldPoint: CGPoint(x: 1, y: 0),
                                                   andNewPoint: CGPoint(x: 0, y: 1))

        let shifted = RotationCalculator(midPoint: CGPoint(x: 100, y: 100))
        let shiftedRotation = shifted.getRotationRadians(byOldPoint: CGPoint(x: 101, y: 100),
                                                         andNewPoint: CGPoint(x: 100, y: 101))

        XCTAssertEqual(baseRotation, shiftedRotation, accuracy: accuracy)
    }
}
