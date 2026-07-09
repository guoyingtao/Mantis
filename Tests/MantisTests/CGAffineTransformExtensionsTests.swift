//
//  CGAffineTransformExtensionsTests.swift
//  MantisTests
//
//  Covers CGAffineTransform.transformed(by:), which composes a CropInfo's
//  translation, rotation, and scale onto the receiver in that fixed order.
//  The order and the fact that it builds *onto* the existing transform (not a
//  fresh identity) are exactly what the crop/export pipeline relies on, so
//  these tests pin both.
//

import XCTest
@testable import Mantis

final class CGAffineTransformExtensionsTests: XCTestCase {

    private let accuracy: CGFloat = 1e-12

    private func cropInfo(translation: CGPoint = .zero,
                          rotation: CGFloat = 0,
                          scaleX: CGFloat = 1,
                          scaleY: CGFloat = 1) -> CropInfo {
        CropInfo(translation: translation,
                 rotation: rotation,
                 scaleX: scaleX,
                 scaleY: scaleY,
                 cropSize: CGSize(width: 100, height: 100),
                 imageViewSize: CGSize(width: 200, height: 200),
                 cropRegion: CropRegion(topLeft: .zero,
                                        topRight: CGPoint(x: 100, y: 0),
                                        bottomLeft: CGPoint(x: 0, y: 100),
                                        bottomRight: CGPoint(x: 100, y: 100)))
    }

    func testTranslationOnlyFromIdentity() {
        var transform = CGAffineTransform.identity
        transform.transformed(by: cropInfo(translation: CGPoint(x: 10, y: 20)))
        XCTAssertEqual(transform, CGAffineTransform(translationX: 10, y: 20))
    }

    func testScaleOnlyFromIdentity() {
        var transform = CGAffineTransform.identity
        transform.transformed(by: cropInfo(scaleX: 2, scaleY: 3))
        XCTAssertEqual(transform, CGAffineTransform(scaleX: 2, y: 3))
    }

    func testTranslateThenScaleComposesInOrder() {
        var transform = CGAffineTransform.identity
        transform.transformed(by: cropInfo(translation: CGPoint(x: 10, y: 20), scaleX: 2, scaleY: 3))
        // identity.translatedBy(10,20).scaledBy(2,3) => [a2 b0 c0 d3 tx10 ty20]
        let expected = CGAffineTransform(a: 2, b: 0, c: 0, d: 3, tx: 10, ty: 20)
        XCTAssertEqual(transform.a, expected.a, accuracy: accuracy)
        XCTAssertEqual(transform.d, expected.d, accuracy: accuracy)
        XCTAssertEqual(transform.tx, expected.tx, accuracy: accuracy)
        XCTAssertEqual(transform.ty, expected.ty, accuracy: accuracy)
        // The composed transform maps (1,1) to (2*1+10, 3*1+20) = (12, 23).
        let mapped = CGPoint(x: 1, y: 1).applying(transform)
        XCTAssertEqual(mapped.x, 12, accuracy: accuracy)
        XCTAssertEqual(mapped.y, 23, accuracy: accuracy)
    }

    func testRotationOnlyRotatesBasisVector() {
        var transform = CGAffineTransform.identity
        transform.transformed(by: cropInfo(rotation: .pi / 2))
        // A quarter turn maps the x-axis unit vector (1,0) to (0,1).
        let mapped = CGPoint(x: 1, y: 0).applying(transform)
        XCTAssertEqual(mapped.x, 0, accuracy: 1e-15)
        XCTAssertEqual(mapped.y, 1, accuracy: 1e-15)
    }

    func testComposesOntoExistingTransformNotIdentity() {
        // Starting from a pre-scaled transform, a pure translation must fold
        // into that scale rather than replace it.
        var transform = CGAffineTransform(scaleX: 2, y: 2)
        transform.transformed(by: cropInfo(translation: CGPoint(x: 5, y: 0)))
        // [2 0 0 2 0 0].translatedBy(5,0) => tx = 2*5 = 10, scale preserved.
        XCTAssertEqual(transform, CGAffineTransform(a: 2, b: 0, c: 0, d: 2, tx: 10, ty: 0))
    }
}
