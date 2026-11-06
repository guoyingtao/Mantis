//
//  RotationControlViewProtocolTests.swift
//  MantisTests
//
//  Imports Mantis without @testable, as a client would, so this file only
//  compiles while the protocol's default implementations stay public.
//

import XCTest
import UIKit
import Mantis

private final class MinimalRotationControl: UIView, RotationControlViewProtocol {
    var isAttachedToCropView = true
    var didUpdateRotationValue: (Angle) -> Void = { _ in }
    var didFinishRotation: () -> Void = {}

    func updateRotationValue(by angle: Angle) -> Bool { true }
    func reset() {}
    func getTotalRotationValue() -> CGFloat { 5 }
}

@MainActor
final class RotationControlViewProtocolTests: XCTestCase {

    func testDefaultSetupUIAppliesTheAllowableFrame() {
        let control = MinimalRotationControl()
        let allowableFrame = CGRect(x: 0, y: 0, width: 240, height: 60)

        control.setupUI(withAllowableFrame: allowableFrame)

        XCTAssertEqual(control.frame, allowableFrame)
    }

    func testDefaultAccessibilitiesReadTheRotationValue() {
        let control = MinimalRotationControl()

        control.setAccessibilities()

        XCTAssertTrue(control.isAccessibilityElement)
        XCTAssertEqual(control.accessibilityValue, "5 degrees")
    }
}
