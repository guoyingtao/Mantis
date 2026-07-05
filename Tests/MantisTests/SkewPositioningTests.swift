//
//  SkewPositioningTests.swift
//  MantisTests
//
//  Pins the pure skew-positioning math extracted from CropView+Skew.swift.
//  These functions have no UIKit/view dependencies, so their behavior can be
//  fixed exactly — which matters because the live skew preview keeps three
//  sources of truth (view-model angle, sublayerTransform, contentInset) in
//  manual sync, making regressions here easy to introduce and hard to spot.
//
//  Containment/shift tests use CATransform3DIdentity, under which
//  `projectDisplacement` is the identity map and every corner is "in front of
//  the camera", reducing the perspective containment test to a plain
//  point-in-rectangle check with hand-computable expectations.
//

import XCTest
@testable import Mantis

final class SkewPositioningTests: XCTestCase {

    private typealias Sut = SkewPositioning
    private let accuracy: CGFloat = 1e-6

    // MARK: - Value type accessors

    func testSkewShiftsCenteredShifts() {
        let shifts = SkewShifts(top: 10, left: 20, bottom: 30, right: 40)
        XCTAssertEqual(shifts.centeredShiftX, (40 - 20) / 2, accuracy: accuracy)
        XCTAssertEqual(shifts.centeredShiftY, (30 - 10) / 2, accuracy: accuracy)
    }

    func testContextCenterOffset() {
        let ctx = makeContext(imageFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                              boundsSize: CGSize(width: 100, height: 100))
        // midX - boundsW/2 = 100 - 50, midY - boundsH/2 = 100 - 50
        XCTAssertEqual(ctx.centerOffset.x, 50, accuracy: accuracy)
        XCTAssertEqual(ctx.centerOffset.y, 50, accuracy: accuracy)
    }

    func testContextImageCornerDisplacements() {
        let ctx = makeContext(imageFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                              boundsSize: CGSize(width: 100, height: 100))
        let corners = ctx.imageCornerDisplacements(from: CGPoint(x: 100, y: 100))
        XCTAssertEqual(corners, [
            CGPoint(x: -100, y: -100),  // TL
            CGPoint(x: 100, y: -100),   // TR
            CGPoint(x: 100, y: 100),    // BR
            CGPoint(x: -100, y: 100)    // BL
        ])
    }

    // MARK: - edgeToEdgeShift blend

    func testEdgeToEdgeShiftZeroDegreesReturnsCentered() {
        let result = Sut.edgeToEdgeShift(deg: 0, positiveEdgeShift: 40, negativeEdgeShift: -20,
                                         centeredShift: 10, rotationDampen: 1, crossAxisActivity: 0)
        XCTAssertEqual(result, 10, accuracy: accuracy)
    }

    func testEdgeToEdgeShiftBelowTransitionUsesEdgeAligned() {
        // deg 4 < transitionStart(8), full dampen -> pure edge alignment.
        let pos = Sut.edgeToEdgeShift(deg: 4, positiveEdgeShift: 40, negativeEdgeShift: -20,
                                      centeredShift: 10, rotationDampen: 1, crossAxisActivity: 0)
        XCTAssertEqual(pos, 40, accuracy: accuracy)
        let neg = Sut.edgeToEdgeShift(deg: -4, positiveEdgeShift: 40, negativeEdgeShift: -20,
                                      centeredShift: 10, rotationDampen: 1, crossAxisActivity: 0)
        XCTAssertEqual(neg, -20, accuracy: accuracy)
    }

    func testEdgeToEdgeShiftAtOrAboveTransitionEndReturnsCentered() {
        for deg in [SkewTuning.transitionEndDegrees, 20] as [CGFloat] {
            let result = Sut.edgeToEdgeShift(deg: deg, positiveEdgeShift: 40, negativeEdgeShift: -20,
                                             centeredShift: 10, rotationDampen: 1, crossAxisActivity: 0)
            XCTAssertEqual(result, 10, accuracy: accuracy, "deg=\(deg) should be fully inscribed")
        }
    }

    func testEdgeToEdgeShiftMidTransitionBlendsHalfway() {
        // deg 10 -> blend = (10-8)/(12-8) = 0.5; edgeAligned=40, centered=10 -> 25.
        let result = Sut.edgeToEdgeShift(deg: 10, positiveEdgeShift: 40, negativeEdgeShift: -20,
                                         centeredShift: 10, rotationDampen: 1, crossAxisActivity: 0)
        XCTAssertEqual(result, 25, accuracy: accuracy)
    }

    func testEdgeToEdgeShiftFullCrossAxisActivityCollapsesToCentered() {
        let result = Sut.edgeToEdgeShift(deg: 4, positiveEdgeShift: 40, negativeEdgeShift: -20,
                                         centeredShift: 10, rotationDampen: 1, crossAxisActivity: 1)
        XCTAssertEqual(result, 10, accuracy: accuracy)
    }

    func testEdgeToEdgeShiftZeroRotationDampenCollapsesToCentered() {
        let result = Sut.edgeToEdgeShift(deg: 4, positiveEdgeShift: 40, negativeEdgeShift: -20,
                                         centeredShift: 10, rotationDampen: 0, crossAxisActivity: 0)
        XCTAssertEqual(result, 10, accuracy: accuracy)
    }

    // MARK: - edgeToEdgeScaleBoost

    func testScaleBoostZeroSkewIsUnity() {
        XCTAssertEqual(Sut.edgeToEdgeScaleBoost(hDeg: 0, vDeg: 0), 1.0, accuracy: accuracy)
    }

    func testScaleBoostAtOrAboveTransitionEndIsUnity() {
        XCTAssertEqual(Sut.edgeToEdgeScaleBoost(hDeg: 12, vDeg: 0), 1.0, accuracy: accuracy)
        XCTAssertEqual(Sut.edgeToEdgeScaleBoost(hDeg: 0, vDeg: 20), 1.0, accuracy: accuracy)
    }

    func testScaleBoostSingleAxisKnownValue() {
        // hDeg=10: hActivity=1, hEdgeFade=(1-10/12)=1/6, intensity=min(10/10,1)*1/6=1/6.
        // boost = 1 + 0.04 * (1/6).
        let expected = 1.0 + 0.04 * (1.0 / 6.0)
        XCTAssertEqual(Sut.edgeToEdgeScaleBoost(hDeg: 10, vDeg: 0), expected, accuracy: accuracy)
    }

    func testScaleBoostIsAxisSymmetric() {
        XCTAssertEqual(Sut.edgeToEdgeScaleBoost(hDeg: 5, vDeg: 0),
                       Sut.edgeToEdgeScaleBoost(hDeg: 0, vDeg: 5), accuracy: accuracy)
    }

    func testScaleBoostNeverBelowUnity() {
        for hDeg in stride(from: CGFloat(0), through: 30, by: 1.5) {
            for vDeg in stride(from: CGFloat(0), through: 30, by: 1.5) {
                XCTAssertGreaterThanOrEqual(Sut.edgeToEdgeScaleBoost(hDeg: hDeg, vDeg: vDeg), 1.0)
            }
        }
    }

    // MARK: - contentInset / lockedCenterInset

    func testContentInsetKnownValues() {
        let ctx = makeContext(imageFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                              boundsSize: CGSize(width: 100, height: 100),
                              contentSize: CGSize(width: 300, height: 300))
        let shifts = SkewShifts(top: 10, left: 20, bottom: 30, right: 40)
        let inset = Sut.contentInset(shifts: shifts, context: ctx)
        // center = (50, 50); contentH-boundsH = contentW-boundsW = 200.
        XCTAssertEqual(inset.top, 10 - 50, accuracy: accuracy)
        XCTAssertEqual(inset.left, 20 - 50, accuracy: accuracy)
        XCTAssertEqual(inset.bottom, (50 + 30) - 200, accuracy: accuracy)
        XCTAssertEqual(inset.right, (50 + 40) - 200, accuracy: accuracy)
    }

    func testLockedCenterInsetKnownValues() {
        let ctx = makeContext(imageFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                              boundsSize: CGSize(width: 100, height: 100),
                              contentSize: CGSize(width: 300, height: 300))
        let inset = Sut.lockedCenterInset(context: ctx)
        XCTAssertEqual(inset.top, -50, accuracy: accuracy)
        XCTAssertEqual(inset.left, -50, accuracy: accuracy)
        XCTAssertEqual(inset.bottom, 50 - 200, accuracy: accuracy)
        XCTAssertEqual(inset.right, 50 - 200, accuracy: accuracy)
    }

    // MARK: - optimalOffset

    func testOptimalOffsetNonMatchingAspectRatioIsCentered() {
        let ctx = makeContext(imageFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                              boundsSize: CGSize(width: 100, height: 100))
        let shifts = SkewShifts(top: 10, left: 20, bottom: 30, right: 40)
        let offset = Sut.optimalOffset(hDeg: 5, vDeg: 5, shifts: shifts, context: ctx,
                                       matchesAspectRatio: false, totalRadians: 0)
        // center (50,50) + centered (10,10).
        XCTAssertEqual(offset.x, 60, accuracy: accuracy)
        XCTAssertEqual(offset.y, 60, accuracy: accuracy)
    }

    func testOptimalOffsetMatchingZeroSkewEqualsCentered() {
        let ctx = makeContext(imageFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                              boundsSize: CGSize(width: 100, height: 100))
        let shifts = SkewShifts(top: 10, left: 20, bottom: 30, right: 40)
        let offset = Sut.optimalOffset(hDeg: 0, vDeg: 0, shifts: shifts, context: ctx,
                                       matchesAspectRatio: true, totalRadians: 0)
        XCTAssertEqual(offset.x, 60, accuracy: accuracy)
        XCTAssertEqual(offset.y, 60, accuracy: accuracy)
    }

    func testOptimalOffsetMatchingSmallHorizontalSkewAlignsEdge() {
        let ctx = makeContext(imageFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                              boundsSize: CGSize(width: 100, height: 100))
        let shifts = SkewShifts(top: 10, left: 20, bottom: 30, right: 40)
        // hDeg=4 (<8, no rotation, no cross-axis) -> X aligns to right edge (40).
        // vDeg=0 -> Y stays centered (10).
        let offset = Sut.optimalOffset(hDeg: 4, vDeg: 0, shifts: shifts, context: ctx,
                                       matchesAspectRatio: true, totalRadians: 0)
        XCTAssertEqual(offset.x, 50 + 40, accuracy: accuracy)
        XCTAssertEqual(offset.y, 50 + 10, accuracy: accuracy)
    }

    // MARK: - Containment & shift search (identity transform)

    func testIsCropBoxInsideCenteredSmallBoxIsInside() {
        let ctx = makeContext(imageFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                              boundsSize: CGSize(width: 100, height: 100),
                              cropCorners: squareCorners(halfSize: 25))
        XCTAssertTrue(Sut.isCropBoxInside(shiftX: 0, shiftY: 0, context: ctx))
    }

    func testIsCropBoxInsideOversizedBoxIsOutside() {
        let ctx = makeContext(imageFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                              boundsSize: CGSize(width: 100, height: 100),
                              cropCorners: squareCorners(halfSize: 150))
        XCTAssertFalse(Sut.isCropBoxInside(shiftX: 0, shiftY: 0, context: ctx))
    }

    func testMaxShiftRightMatchesGeometry() {
        // 200x200 image, 50x50 crop (half 25) centered. Shifting the anchor in
        // +x keeps the box inside until the image's right edge reaches the box:
        // max shift = imageHalf(100) - cropHalf(25) = 75.
        let ctx = makeContext(imageFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                              boundsSize: CGSize(width: 100, height: 100),
                              cropCorners: squareCorners(halfSize: 25))
        let shift = Sut.maxShift(dirX: 1, dirY: 0, context: ctx)
        XCTAssertEqual(shift, 75, accuracy: 0.05)
    }

    func testMaxShiftsSymmetricForCenteredSquare() {
        let ctx = makeContext(imageFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                              boundsSize: CGSize(width: 100, height: 100),
                              cropCorners: squareCorners(halfSize: 25))
        let shifts = Sut.maxShifts(context: ctx)
        XCTAssertEqual(shifts.top, 75, accuracy: 0.05)
        XCTAssertEqual(shifts.bottom, 75, accuracy: 0.05)
        XCTAssertEqual(shifts.left, 75, accuracy: 0.05)
        XCTAssertEqual(shifts.right, 75, accuracy: 0.05)
    }

    // MARK: - Helpers

    private func makeContext(imageFrame: CGRect,
                             boundsSize: CGSize,
                             contentSize: CGSize = CGSize(width: 300, height: 300),
                             cropCorners: [CGPoint] = [],
                             transform: CATransform3D = CATransform3DIdentity) -> SkewInsetContext {
        SkewInsetContext(imageFrame: imageFrame,
                         boundsSize: boundsSize,
                         contentSize: contentSize,
                         cropCorners: cropCorners,
                         transform: transform)
    }

    private func squareCorners(halfSize half: CGFloat) -> [CGPoint] {
        [CGPoint(x: -half, y: -half), CGPoint(x: half, y: -half),
         CGPoint(x: half, y: half), CGPoint(x: -half, y: half)]
    }
}
