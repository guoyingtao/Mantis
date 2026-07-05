//
//  PerspectiveTransformHelperTests.swift
//  MantisTests
//
//  Exercises the pure 3D-perspective math that backs the skew feature
//  (v2.29). These functions have no UIKit dependencies, so their behavior
//  can be pinned exactly — which matters because the live skew preview keeps
//  three sources of truth (view-model angle, sublayerTransform, contentInset)
//  in manual sync, making regressions here easy to introduce and hard to spot.
//

import XCTest
@testable import Mantis

final class PerspectiveTransformHelperTests: XCTestCase {

    private typealias Helper = PerspectiveTransformHelper

    private let accuracy: CGFloat = 1e-9

    /// Builds the perspective-only base matrix (identity + m34), the starting
    /// point every skew transform is derived from.
    private func perspectiveBase(depth: CGFloat = PerspectiveTransformHelper.perspectiveDepth) -> CATransform3D {
        var base = CATransform3DIdentity
        base.m34 = depth
        return base
    }

    // MARK: - horizontalSkewTransform3D

    func testHorizontalSkewZeroDegreesIsPerspectiveOnly() {
        let transform = Helper.horizontalSkewTransform3D(degrees: 0)
        // Rotation by 0 leaves only the perspective term.
        XCTAssertTrue(CATransform3DEqualToTransform(transform, perspectiveBase()))
        XCTAssertEqual(transform.m34, Helper.perspectiveDepth, accuracy: accuracy)
        XCTAssertEqual(transform.m41, 0, accuracy: accuracy)
    }

    func testHorizontalSkewRotatesAboutYAxis() {
        let degrees: CGFloat = 20
        let transform = Helper.horizontalSkewTransform3D(degrees: degrees)
        // Y-axis rotation puts cos(θ) on m11 and leaves m22 == 1.
        XCTAssertEqual(transform.m11, cos(degrees * .pi / 180), accuracy: 1e-6)
        XCTAssertEqual(transform.m22, 1, accuracy: 1e-6)
    }

    func testHorizontalSkewNoTranslationAtOrBelowThreshold() {
        // At exactly the threshold the branch (strictly `>`) must not fire, so
        // the result is pure rotation of the perspective base — no translation.
        let degrees = Helper.translateThresholdDegrees
        let expected = CATransform3DRotate(perspectiveBase(), degrees * .pi / 180, 0, 1, 0)
        XCTAssertTrue(CATransform3DEqualToTransform(Helper.horizontalSkewTransform3D(degrees: degrees), expected))
    }

    func testHorizontalSkewAppliesTranslationAboveThreshold() {
        let degrees: CGFloat = 15 // 5 degrees over threshold
        let rotated = CATransform3DRotate(perspectiveBase(), degrees * .pi / 180, 0, 1, 0)
        let excess = degrees - Helper.translateThresholdDegrees
        // direction is negative for positive degrees, factor == excess * 2
        let expected = CATransform3DTranslate(rotated, -1 * excess * 2.0, 0, 0)
        XCTAssertTrue(CATransform3DEqualToTransform(Helper.horizontalSkewTransform3D(degrees: degrees), expected))

        // The translation must actually change the matrix versus rotation alone.
        XCTAssertFalse(CATransform3DEqualToTransform(Helper.horizontalSkewTransform3D(degrees: degrees), rotated))
    }

    func testHorizontalSkewTranslationDirectionFlipsWithSign() {
        let positive = Helper.horizontalSkewTransform3D(degrees: 15)
        let negative = Helper.horizontalSkewTransform3D(degrees: -15)
        // cos is even, so m11 matches; the translation flips sign, so m41 mirrors.
        XCTAssertEqual(positive.m11, negative.m11, accuracy: accuracy)
        XCTAssertEqual(positive.m41, -negative.m41, accuracy: accuracy)
        XCTAssertNotEqual(positive.m41, 0, accuracy: accuracy)
    }

    // MARK: - verticalSkewTransform3D

    func testVerticalSkewRotatesAboutXAxis() {
        let degrees: CGFloat = 20
        let transform = Helper.verticalSkewTransform3D(degrees: degrees)
        // X-axis rotation puts cos(θ) on m22 and leaves m11 == 1.
        XCTAssertEqual(transform.m22, cos(degrees * .pi / 180), accuracy: 1e-6)
        XCTAssertEqual(transform.m11, 1, accuracy: 1e-6)
        // Rotating the perspective base scales the m34 depth term by cos(θ).
        XCTAssertEqual(transform.m34, Helper.perspectiveDepth * cos(degrees * .pi / 180), accuracy: 1e-9)
    }

    func testVerticalSkewAppliesTranslationAboveThresholdOnYAxis() {
        let degrees: CGFloat = -18
        let rotated = CATransform3DRotate(perspectiveBase(), degrees * .pi / 180, 1, 0, 0)
        let excess = abs(degrees) - Helper.translateThresholdDegrees
        // direction is +1 for negative degrees, translation is on the Y axis
        let expected = CATransform3DTranslate(rotated, 0, 1 * excess * 2.0, 0)
        XCTAssertTrue(CATransform3DEqualToTransform(Helper.verticalSkewTransform3D(degrees: degrees), expected))
    }

    // MARK: - combinedSkewTransform3D

    func testCombinedSkewZeroIsIdentity() {
        XCTAssertTrue(CATransform3DEqualToTransform(
            Helper.combinedSkewTransform3D(horizontalDegrees: 0, verticalDegrees: 0),
            CATransform3DIdentity))
    }

    func testCombinedSingleAxisMatchesDedicatedTransform() {
        // With a single axis and zoom 1 the combined path performs exactly the
        // same operations as the single-axis helpers.
        XCTAssertTrue(CATransform3DEqualToTransform(
            Helper.combinedSkewTransform3D(horizontalDegrees: 15, verticalDegrees: 0, zoomScale: 1),
            Helper.horizontalSkewTransform3D(degrees: 15)))
        XCTAssertTrue(CATransform3DEqualToTransform(
            Helper.combinedSkewTransform3D(horizontalDegrees: 0, verticalDegrees: 15, zoomScale: 1),
            Helper.verticalSkewTransform3D(degrees: 15)))
    }

    func testCombinedSkewClampsZoomBelowOne() {
        // effectiveZoom = max(zoomScale, 1), so 0.5 behaves like 1.0.
        XCTAssertTrue(CATransform3DEqualToTransform(
            Helper.combinedSkewTransform3D(horizontalDegrees: 20, verticalDegrees: 0, zoomScale: 0.5),
            Helper.combinedSkewTransform3D(horizontalDegrees: 20, verticalDegrees: 0, zoomScale: 1)))
    }

    func testCombinedSkewScalesPerspectiveDepthByZoom() {
        // The base m34 is depth / effectiveZoom before rotation scales it by
        // cos(θ). The rotation angle is identical here, so doubling the zoom
        // must halve the resulting m34 — the "perspective depth divided by
        // zoom" contract, isolated from the cos factor.
        let atZoom1 = Helper.combinedSkewTransform3D(horizontalDegrees: 20, verticalDegrees: 0, zoomScale: 1)
        let atZoom2 = Helper.combinedSkewTransform3D(horizontalDegrees: 20, verticalDegrees: 0, zoomScale: 2)
        XCTAssertEqual(atZoom2.m34, atZoom1.m34 / 2, accuracy: 1e-12)
    }

    func testCombinedSkewBoostsEffectiveZoomAtMaxCombinedSkew() {
        // Both axes at max (30°): combinedIntensity == 1, so effectiveZoom
        // becomes 1 * (1 + 0.3) = 1.3. The base m34 (depth / 1.3) is then
        // scaled by cos(30°) for each of the two rotations.
        let radians = Helper.maxSkewDegrees * .pi / 180
        let transform = Helper.combinedSkewTransform3D(horizontalDegrees: Helper.maxSkewDegrees,
                                                       verticalDegrees: Helper.maxSkewDegrees,
                                                       zoomScale: 1)
        let expected = Helper.perspectiveDepth / 1.3 * cos(radians) * cos(radians)
        XCTAssertEqual(transform.m34, expected, accuracy: 1e-9)

        // Sanity: the boost really did raise effectiveZoom above 1, so |m34| is
        // smaller than it would be without the boost (depth * cos^2 at zoom 1).
        let withoutBoost = Helper.perspectiveDepth * cos(radians) * cos(radians)
        XCTAssertLessThan(abs(transform.m34), abs(withoutBoost))
    }

    // MARK: - projectDisplacement

    func testProjectDisplacementThroughIdentityIsUnchanged() {
        let point = CGPoint(x: 3, y: 4)
        let projected = Helper.projectDisplacement(point, through: CATransform3DIdentity)
        XCTAssertEqual(projected.x, 3, accuracy: accuracy)
        XCTAssertEqual(projected.y, 4, accuracy: accuracy)
    }

    func testProjectDisplacementAppliesTranslation() {
        let transform = CATransform3DMakeTranslation(10, 20, 0)
        let projected = Helper.projectDisplacement(CGPoint(x: 1, y: 2), through: transform)
        XCTAssertEqual(projected.x, 11, accuracy: accuracy)
        XCTAssertEqual(projected.y, 22, accuracy: accuracy)
    }

    func testProjectDisplacementAppliesPerspectiveDivision() {
        var transform = CATransform3DIdentity
        transform.m14 = 0.1 // w depends on x
        let projected = Helper.projectDisplacement(CGPoint(x: 2, y: 0), through: transform)
        // w = 2 * 0.1 + 1 = 1.2, x = 2 / 1.2
        XCTAssertEqual(projected.x, 2 / 1.2, accuracy: 1e-9)
        XCTAssertEqual(projected.y, 0, accuracy: 1e-9)
    }

    func testProjectDisplacementReturnsInputWhenWIsDegenerate() {
        var transform = CATransform3DIdentity
        transform.m44 = 0 // w collapses to 0
        let point = CGPoint(x: 3, y: 4)
        let projected = Helper.projectDisplacement(point, through: transform)
        XCTAssertEqual(projected.x, point.x, accuracy: accuracy)
        XCTAssertEqual(projected.y, point.y, accuracy: accuracy)
    }

    // MARK: - allProjectionsInFrontOfCamera

    func testAllProjectionsInFrontOfCameraTrueForIdentity() {
        let corners = [CGPoint(x: 1, y: 1), CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1)]
        XCTAssertTrue(Helper.allProjectionsInFrontOfCamera(corners, through: CATransform3DIdentity))
    }

    func testAllProjectionsInFrontOfCameraFalseWhenBehindCamera() {
        var transform = CATransform3DIdentity
        transform.m44 = -1 // every w becomes negative
        XCTAssertFalse(Helper.allProjectionsInFrontOfCamera([CGPoint(x: 1, y: 1)], through: transform))
    }

    func testAllProjectionsInFrontOfCameraFalseWhenAnyCornerIsBehind() {
        // m14 large & negative pushes the +x corner behind the camera plane
        // while the -x corner stays in front.
        var transform = CATransform3DIdentity
        transform.m14 = -1
        let corners = [CGPoint(x: -1, y: 0), CGPoint(x: 2, y: 0)] // w = 2 and -1
        XCTAssertFalse(Helper.allProjectionsInFrontOfCamera(corners, through: transform))
    }

    // MARK: - centeredTransform

    func testCenteredTransformReturnsInputWhenCornerCountWrong() {
        let input = CATransform3DMakeTranslation(7, 8, 0)
        let result = Helper.centeredTransform(input,
                                              imageCornerDisplacements: [.zero, .zero, .zero],
                                              targetCenter: .zero,
                                              factor: 1)
        XCTAssertTrue(CATransform3DEqualToTransform(result, input))
    }

    func testCenteredTransformReturnsInputWhenFactorZero() {
        let input = CATransform3DMakeTranslation(7, 8, 0)
        let corners = [CGPoint(x: 4, y: 4), CGPoint(x: 6, y: 4), CGPoint(x: 6, y: 6), CGPoint(x: 4, y: 6)]
        let result = Helper.centeredTransform(input,
                                              imageCornerDisplacements: corners,
                                              targetCenter: .zero,
                                              factor: 0)
        XCTAssertTrue(CATransform3DEqualToTransform(result, input))
    }

    func testCenteredTransformShiftsProjectedCenterToTarget() {
        // Corners centered at (5, 5); target (0, 0) => full-factor shift of (-5, -5).
        let corners = [CGPoint(x: 4, y: 4), CGPoint(x: 6, y: 4), CGPoint(x: 6, y: 6), CGPoint(x: 4, y: 6)]
        let result = Helper.centeredTransform(CATransform3DIdentity,
                                              imageCornerDisplacements: corners,
                                              targetCenter: .zero,
                                              factor: 1)
        XCTAssertEqual(result.m41, -5, accuracy: accuracy)
        XCTAssertEqual(result.m42, -5, accuracy: accuracy)
    }

    func testCenteredTransformScalesShiftByFactor() {
        let corners = [CGPoint(x: 4, y: 4), CGPoint(x: 6, y: 4), CGPoint(x: 6, y: 6), CGPoint(x: 4, y: 6)]
        let result = Helper.centeredTransform(CATransform3DIdentity,
                                              imageCornerDisplacements: corners,
                                              targetCenter: .zero,
                                              factor: 0.5)
        XCTAssertEqual(result.m41, -2.5, accuracy: accuracy)
        XCTAssertEqual(result.m42, -2.5, accuracy: accuracy)
    }

    func testCenteredTransformClampsFactorAboveOne() {
        let corners = [CGPoint(x: 4, y: 4), CGPoint(x: 6, y: 4), CGPoint(x: 6, y: 6), CGPoint(x: 4, y: 6)]
        let atOne = Helper.centeredTransform(CATransform3DIdentity,
                                             imageCornerDisplacements: corners,
                                             targetCenter: .zero,
                                             factor: 1)
        let aboveOne = Helper.centeredTransform(CATransform3DIdentity,
                                                imageCornerDisplacements: corners,
                                                targetCenter: .zero,
                                                factor: 5)
        XCTAssertTrue(CATransform3DEqualToTransform(atOne, aboveOne))
    }

    // MARK: - allPointsInsideConvexPolygon

    private let unitSquare = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0),
                              CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)]

    func testPointInsideSquare() {
        XCTAssertTrue(Helper.allPointsInsideConvexPolygon([CGPoint(x: 0.5, y: 0.5)], polygon: unitSquare))
    }

    func testPointOutsideSquare() {
        XCTAssertFalse(Helper.allPointsInsideConvexPolygon([CGPoint(x: 2, y: 2)], polygon: unitSquare))
    }

    func testAllPointsMustBeInside() {
        let points = [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 5, y: 5)]
        XCTAssertFalse(Helper.allPointsInsideConvexPolygon(points, polygon: unitSquare))
    }

    func testDegeneratePolygonIsNeverContaining() {
        let line = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1)]
        XCTAssertFalse(Helper.allPointsInsideConvexPolygon([CGPoint(x: 0.5, y: 0.5)], polygon: line))
    }

    func testConcavePolygonNotchIsCorrectlyExcluded() {
        // A "U" shape. A point in the gap between the prongs is outside the
        // polygon — the case the old cross-product convex test got wrong and
        // the reason this is ray-casting now.
        let uShape = [
            CGPoint(x: 0, y: 0), CGPoint(x: 4, y: 0), CGPoint(x: 4, y: 4),
            CGPoint(x: 3, y: 4), CGPoint(x: 3, y: 2), CGPoint(x: 1, y: 2),
            CGPoint(x: 1, y: 4), CGPoint(x: 0, y: 4)
        ]
        XCTAssertFalse(Helper.allPointsInsideConvexPolygon([CGPoint(x: 2, y: 3)], polygon: uShape),
                       "point in the U's notch must be outside")
        XCTAssertTrue(Helper.allPointsInsideConvexPolygon([CGPoint(x: 0.5, y: 3)], polygon: uShape),
                      "point inside the left prong must be inside")
        XCTAssertTrue(Helper.allPointsInsideConvexPolygon([CGPoint(x: 2, y: 1)], polygon: uShape),
                      "point inside the base must be inside")
    }

    // MARK: - computeCompensatingScale

    func testCompensatingScaleIsOneWhenImageAlreadyCoversCrop() {
        let imageCorners = [CGPoint(x: -10, y: -10), CGPoint(x: 10, y: -10),
                            CGPoint(x: 10, y: 10), CGPoint(x: -10, y: 10)]
        let visibleCorners = [CGPoint(x: -2, y: -2), CGPoint(x: 2, y: -2),
                              CGPoint(x: 2, y: 2), CGPoint(x: -2, y: 2)]
        let scale = Helper.computeCompensatingScale(imageCornerDisplacements: imageCorners,
                                                    visibleCornerDisplacements: visibleCorners,
                                                    perspectiveTransform: CATransform3DIdentity)
        XCTAssertEqual(scale, 1.0, accuracy: accuracy)
    }

    func testCompensatingScaleGrowsUntilImageCoversCrop() {
        // Image half-extent 1, crop half-extent 2 => needs scale ~2 to cover.
        let imageCorners = [CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1),
                            CGPoint(x: 1, y: 1), CGPoint(x: -1, y: 1)]
        let visibleCorners = [CGPoint(x: -2, y: -2), CGPoint(x: 2, y: -2),
                              CGPoint(x: 2, y: 2), CGPoint(x: -2, y: 2)]
        let scale = Helper.computeCompensatingScale(imageCornerDisplacements: imageCorners,
                                                    visibleCornerDisplacements: visibleCorners,
                                                    perspectiveTransform: CATransform3DIdentity)
        XCTAssertGreaterThanOrEqual(scale, 2.0)
        XCTAssertEqual(scale, 2.0, accuracy: 0.05, "binary search should converge just above the exact 2.0")
    }
}
