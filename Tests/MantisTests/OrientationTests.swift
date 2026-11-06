//
//  OrientationTests.swift
//  MantisTests
//
//  Covers the decision behind Orientation.treatAsPortrait, which picks between
//  the portrait layout (toolbar at the bottom, horizontal dial) and the
//  landscape layout (toolbar at the side, rotated dial) for every layout path.
//

import XCTest
@testable import Mantis

final class OrientationTests: XCTestCase {

    private struct Case {
        let orientation: UIInterfaceOrientation
        let idiom: UIUserInterfaceIdiom
        let verticalSizeClass: UIUserInterfaceSizeClass?
        let expected: Bool
    }

    func testShouldTreatAsPortrait() {
        let cases: [Case] = [
            // iPhone in portrait
            Case(orientation: .portrait, idiom: .phone, verticalSizeClass: .regular, expected: true),
            Case(orientation: .portraitUpsideDown, idiom: .phone, verticalSizeClass: .regular, expected: true),
            // iPhone in landscape
            Case(orientation: .landscapeLeft, idiom: .phone, verticalSizeClass: .compact, expected: false),
            Case(orientation: .landscapeRight, idiom: .phone, verticalSizeClass: .compact, expected: false),
            // Inner display of a foldable iPhone in landscape
            Case(orientation: .landscapeLeft, idiom: .phone, verticalSizeClass: .regular, expected: true),
            Case(orientation: .landscapeRight, idiom: .phone, verticalSizeClass: .regular, expected: true),
            // Only a regular vertical size class means there is room for the portrait layout
            Case(orientation: .landscapeLeft, idiom: .phone, verticalSizeClass: .unspecified, expected: false),
            Case(orientation: .landscapeLeft, idiom: .phone, verticalSizeClass: nil, expected: false),
            Case(orientation: .unknown, idiom: .phone, verticalSizeClass: .compact, expected: false),
            // Other devices always use the portrait layout
            Case(orientation: .landscapeLeft, idiom: .pad, verticalSizeClass: .compact, expected: true),
            Case(orientation: .landscapeRight, idiom: .pad, verticalSizeClass: nil, expected: true),
            Case(orientation: .landscapeLeft, idiom: .mac, verticalSizeClass: .compact, expected: true)
        ]

        for testCase in cases {
            XCTAssertEqual(Orientation.shouldTreatAsPortrait(interfaceOrientation: testCase.orientation,
                                                             userInterfaceIdiom: testCase.idiom,
                                                             verticalSizeClass: testCase.verticalSizeClass),
                           testCase.expected,
                           "\(testCase)")
        }
    }
}
