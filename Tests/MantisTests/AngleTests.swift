//
//  AngleTests.swift
//  MantisTests
//
//  Covers the Angle value type: radians<->degrees conversion and the arithmetic
//  operator overloads used throughout rotation math. These are tiny pure
//  functions, but they underpin every dial/rotation calculation, so a wrong
//  conversion factor or a mis-wired operator silently skews every angle.
//

import XCTest
@testable import Mantis

final class AngleTests: XCTestCase {

    private let accuracy: CGFloat = 1e-12

    // MARK: - Initialization & conversion

    func testInitWithRadiansExposesRadians() {
        XCTAssertEqual(Angle(radians: .pi).radians, .pi, accuracy: accuracy)
    }

    func testRadiansConvertToDegrees() {
        XCTAssertEqual(Angle(radians: .pi).degrees, 180, accuracy: accuracy)
        XCTAssertEqual(Angle(radians: .pi / 2).degrees, 90, accuracy: accuracy)
        XCTAssertEqual(Angle(radians: 0).degrees, 0, accuracy: accuracy)
    }

    func testInitWithDegreesConvertsToRadians() {
        XCTAssertEqual(Angle(degrees: 180).radians, .pi, accuracy: accuracy)
        XCTAssertEqual(Angle(degrees: 90).radians, .pi / 2, accuracy: accuracy)
        XCTAssertEqual(Angle(degrees: -45).radians, -.pi / 4, accuracy: accuracy)
    }

    func testDegreesSetterUpdatesRadians() {
        let angle = Angle(radians: 0)
        angle.degrees = 90
        XCTAssertEqual(angle.radians, .pi / 2, accuracy: accuracy)
    }

    func testRoundTripDegreesRadians() {
        // Converting degrees -> radians -> degrees must be an identity.
        XCTAssertEqual(Angle(degrees: 137).degrees, 137, accuracy: 1e-9)
    }

    // MARK: - description

    func testDescriptionFormatsDegreesWithTwoDecimals() {
        XCTAssertEqual(Angle(degrees: 45).description, "45.00°")
        XCTAssertEqual(Angle(degrees: -12.5).description, "-12.50°")
    }

    // MARK: - Arithmetic operators

    func testAddition() {
        let sum = Angle(degrees: 30) + Angle(degrees: 60)
        XCTAssertEqual(sum.degrees, 90, accuracy: 1e-9)
    }

    func testAdditionAssignment() {
        var angle = Angle(degrees: 30)
        angle += Angle(degrees: 15)
        XCTAssertEqual(angle.degrees, 45, accuracy: 1e-9)
    }

    func testSubtraction() {
        let diff = Angle(degrees: 90) - Angle(degrees: 30)
        XCTAssertEqual(diff.degrees, 60, accuracy: 1e-9)
    }

    func testSubtractionAssignment() {
        var angle = Angle(degrees: 90)
        angle -= Angle(degrees: 30)
        XCTAssertEqual(angle.degrees, 60, accuracy: 1e-9)
    }

    func testMultiplicationMultipliesRadians() {
        // `*` multiplies the underlying radians, not the degrees.
        let product = Angle(radians: 2) * Angle(radians: 3)
        XCTAssertEqual(product.radians, 6, accuracy: accuracy)
    }

    func testUnaryMinusNegatesRadians() {
        let negated = -Angle(degrees: 45)
        XCTAssertEqual(negated.degrees, -45, accuracy: 1e-9)
    }

    func testDivisionDividesRadians() {
        let quotient = Angle(radians: 6) / Angle(radians: 2)
        XCTAssertEqual(quotient.radians, 3, accuracy: accuracy)
    }

    // MARK: - Division by zero guards

    func testDivisionByZeroWithPositiveNumeratorIsPositiveInfinity() {
        let result = Angle(radians: 5) / Angle(radians: 0)
        XCTAssertEqual(result.radians, .infinity)
    }

    func testDivisionByZeroWithNegativeNumeratorIsNegativeInfinity() {
        let result = Angle(radians: -5) / Angle(radians: 0)
        XCTAssertEqual(result.radians, -.infinity)
    }

    func testZeroDividedByZeroIsZero() {
        let result = Angle(radians: 0) / Angle(radians: 0)
        XCTAssertEqual(result.radians, 0, accuracy: accuracy)
    }

    // MARK: - Comparable

    func testLessThanComparesByRadians() {
        XCTAssertTrue(Angle(degrees: 30) < Angle(degrees: 60))
        XCTAssertFalse(Angle(degrees: 60) < Angle(degrees: 30))
    }

    func testGreaterThanDerivedFromComparable() {
        XCTAssertTrue(Angle(degrees: 90) > Angle(degrees: 45))
    }
}
