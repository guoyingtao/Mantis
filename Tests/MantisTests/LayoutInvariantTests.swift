//
//  LayoutInvariantTests.swift
//  MantisTests
//

import XCTest
@testable import Mantis

/// Hosts a real CropViewController (real CropView, toolbar and rotation control)
/// in a window and checks geometry that has to hold after layout, instead of
/// checking calls on fakes. Each test replays the scenario of a past layout bug.
///
/// The test process has no window scene, so Orientation reports portrait and
/// only the portrait layout is covered here.
@MainActor
final class LayoutInvariantTests: XCTestCase {
    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    // MARK: - Baseline

    func testInitialLayoutWithRotationDial() throws {
        let cropVC = makeCropViewController()
        host(cropVC)
        waitForLayoutToSettle()

        try assertSettledLayout(of: cropVC)
    }

    func testInitialLayoutWithSlideDial() throws {
        var config = Mantis.Config()
        config.cropViewConfig.builtInRotationControlViewType = .slideDial()
        let cropVC = makeCropViewController(config: config)
        host(cropVC)
        waitForLayoutToSettle()

        try assertSettledLayout(of: cropVC)
    }

    // MARK: - #553 A skipped view transition must not leave the crop box hidden

    func testCropBoxStaysVisibleWhenTransitionIsSkipped() throws {
        let cropVC = makeCropViewController()
        host(cropVC)
        waitForLayoutToSettle()
        cropVC.interfaceOrientationProvider = { .unknown }

        cropVC.viewWillTransition(to: CGSize(width: 844, height: 390), with: FakeTransitionCoordinator())
        waitForLayoutToSettle()

        try assertSettledLayout(of: cropVC)
    }

    func testCropBoxReappearsAfterUpsideDownTransition() throws {
        let cropVC = makeCropViewController()
        host(cropVC)
        waitForLayoutToSettle()
        cropVC.interfaceOrientationProvider = { .portraitUpsideDown }

        cropVC.viewWillTransition(to: CGSize(width: 390, height: 844), with: FakeTransitionCoordinator())
        waitForLayoutToSettle()

        try assertSettledLayout(of: cropVC)
    }

    // MARK: - #551 The rotation control follows a size change that isn't a rotation

    // Switching between the outer and inner displays of a foldable iPhone changes
    // the crop view size while the interface stays in the same orientation.
    func testSlideDialFollowsCropViewSizeChangeWithoutRotation() throws {
        var config = Mantis.Config()
        config.cropViewConfig.builtInRotationControlViewType = .slideDial()
        let cropVC = makeCropViewController(config: config)
        host(cropVC, size: CGSize(width: 390, height: 844))
        waitForLayoutToSettle()
        cropVC.interfaceOrientationProvider = { .portrait }
        let cropView = try XCTUnwrap(cropVC.cropView as? CropView)
        let slideDial = try XCTUnwrap(cropView.rotationControlView as? SlideDial)
        let oldDialLength = slideDial.bounds.width

        // UIKit calls viewWillTransition(to:with:) before it resizes the view.
        let innerDisplaySize = CGSize(width: 760, height: 844)
        cropVC.viewWillTransition(to: innerDisplaySize, with: FakeTransitionCoordinator())
        window?.frame.size = innerDisplaySize
        window?.layoutIfNeeded()
        waitForLayoutToSettle()

        try assertSettledLayout(of: cropVC)
        let expectedDialLength = min(cropView.bounds.width, cropView.bounds.height) * slideDial.getLengthRatio()
        XCTAssertNotEqual(expectedDialLength, oldDialLength, accuracy: 1, "precondition: the dial length should change")
        XCTAssertEqual(slideDial.bounds.width, expectedDialLength, accuracy: 0.5)
        XCTAssertEqual(slideDial.frame.midX, cropView.cropAuxiliaryIndicatorView.frame.midX, accuracy: 0.5)
    }

    // MARK: - #543 Resizing the crop box stays within the content bounds

    func testDraggingCropBoxEdgePastContentBoundsStopsAtTheEdge() throws {
        let cropVC = makeCropViewController()
        host(cropVC)
        waitForLayoutToSettle()
        let cropView = try XCTUnwrap(cropVC.cropView as? CropView)
        try zoomInUntilImageReachesBelowCropView(cropView)
        let contentBounds = cropView.getContentBounds()
        let originalCropBox = cropView.cropAuxiliaryIndicatorView.frame

        dragCropBoxBottomEdge(of: cropView, to: cropView.bounds.maxY + 100)

        let cropBox = cropView.cropAuxiliaryIndicatorView.frame
        assertRect(cropBox, isInside: contentBounds, "crop box dragged outside the content bounds")
        XCTAssertEqual(cropBox.maxY, contentBounds.maxY, accuracy: 0.5, "the drag should stop at the content edge")
        XCTAssertEqual(cropBox.minY, originalCropBox.minY, accuracy: 0.5)
        XCTAssertLessThanOrEqual(frame(of: cropView.cropAuxiliaryIndicatorView, in: cropVC.view).maxY,
                                 frame(of: cropVC.cropToolbar, in: cropVC.view).minY,
                                 "crop box reaches under the toolbar")
    }

    func testDraggingLockedRatioCropBoxPastContentBoundsIsRejected() throws {
        var config = Mantis.Config()
        config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
        let cropVC = makeCropViewController(config: config)
        host(cropVC)
        waitForLayoutToSettle()
        let cropView = try XCTUnwrap(cropVC.cropView as? CropView)
        XCTAssertTrue(cropView.aspectRatioLockEnabled, "precondition: the ratio should be locked")
        try zoomInUntilImageReachesBelowCropView(cropView)
        let originalCropBox = cropView.cropAuxiliaryIndicatorView.frame

        dragCropBoxBottomEdge(of: cropView, to: cropView.bounds.maxY + 100)

        // Clamping edge by edge would break the ratio, so the whole update is dropped.
        assertRect(cropView.cropAuxiliaryIndicatorView.frame, equals: originalCropBox)
        assertRect(cropView.cropAuxiliaryIndicatorView.frame, isInside: cropView.getContentBounds(),
                   "crop box dragged outside the content bounds")
    }

    // MARK: - #521 Embedded mode leaves the safe area to the embedding parent

    func testEmbeddedCropViewControllerDoesNotApplyInheritedSafeArea() throws {
        var config = Mantis.Config()
        config.cropToolbarConfig.mode = .embedded
        let cropVC = makeCropViewController(config: config)

        // The parent already keeps its own content out of these insets, and the
        // child's view still reports them because it covers the parent's view.
        // Force them so the check doesn't depend on the simulator's screen.
        let container = UIViewController()
        container.additionalSafeAreaInsets = UIEdgeInsets(top: 40, left: 0, bottom: 30, right: 0)
        host(container)
        container.addChild(cropVC)
        cropVC.view.frame = container.view.bounds
        container.view.addSubview(cropVC.view)
        cropVC.didMove(toParent: container)
        container.view.layoutIfNeeded()
        waitForLayoutToSettle()

        XCTAssertGreaterThan(cropVC.view.safeAreaInsets.top, 0, "precondition: the child should inherit safe area insets")
        XCTAssertGreaterThan(cropVC.view.safeAreaInsets.bottom, 0, "precondition: the child should inherit safe area insets")
        assertRect(try XCTUnwrap(cropVC.stackView).frame, equals: cropVC.view.bounds)
        try assertSettledLayout(of: cropVC)
    }

    func testFullScreenCropViewControllerStaysInSafeArea() throws {
        let cropVC = makeCropViewController()
        cropVC.additionalSafeAreaInsets = UIEdgeInsets(top: 40, left: 0, bottom: 30, right: 0)
        host(cropVC)
        waitForLayoutToSettle()

        assertRect(try XCTUnwrap(cropVC.stackView).frame, equals: cropVC.view.safeAreaLayoutGuide.layoutFrame)
        try assertSettledLayout(of: cropVC)
    }
}

// MARK: - Helpers
extension LayoutInvariantTests {
    private func makeCropViewController(config: Mantis.Config = Mantis.Config()) -> CropViewController {
        let image = TestHelper.createATestImage(bySize: CGSize(width: 400, height: 300))
        return Mantis.cropViewController(image: image, config: config)
    }

    private func host(_ viewController: UIViewController, size: CGSize = CGSize(width: 390, height: 844)) {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.view.layoutIfNeeded()
        self.window = window
    }

    /// Waits past handleViewWillTransition()'s 0.1 s dispatch. Both are main queue
    /// dispatches, so that one always runs first, however slow the machine is.
    private func waitForLayoutToSettle() {
        let settled = expectation(description: "layout settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settled.fulfill() }
        wait(for: [settled], timeout: 2)
    }

    /// Zooms into the image center so the image extends below the crop view,
    /// under the rotation control and the toolbar.
    private func zoomInUntilImageReachesBelowCropView(_ cropView: CropView,
                                                      file: StaticString = #filePath,
                                                      line: UInt = #line) throws {
        let imageContainer = try XCTUnwrap(cropView.cropWorkbenchView.imageContainer, file: file, line: line)
        let zoomRect = imageContainer.bounds.insetBy(dx: imageContainer.bounds.width / 3,
                                                     dy: imageContainer.bounds.height / 3)
        cropView.cropWorkbenchView.zoom(to: zoomRect, animated: false)

        let imageFrame = frame(of: imageContainer, in: cropView)
        XCTAssertGreaterThan(imageFrame.maxY, cropView.bounds.maxY,
                             "precondition: the zoomed image should reach below the crop view", file: file, line: line)
    }

    /// Replays the calls touchesBegan(_:with:) and touchesMoved(_:with:) make for a
    /// one-finger drag of the crop box's bottom edge.
    private func dragCropBoxBottomEdge(of cropView: CropView, to targetY: CGFloat) {
        let cropBox = cropView.cropAuxiliaryIndicatorView.frame
        let startPoint = CGPoint(x: cropBox.midX, y: cropBox.maxY)
        cropView.viewModel.prepareForCrop(byTouchPoint: startPoint)

        // Move in steps, like a real pan, so each update starts from the last one.
        let steps = 10
        for step in 1...steps {
            let progress = CGFloat(step) / CGFloat(steps)
            let touchPoint = CGPoint(x: startPoint.x, y: startPoint.y + (targetY - startPoint.y) * progress)
            cropView.updateCropBoxFrame(withTouchPoint: touchPoint)
        }
    }

    /// Checks that hold for any crop view that is idle after layout.
    private func assertSettledLayout(of cropVC: CropViewController,
                                     file: StaticString = #filePath,
                                     line: UInt = #line) throws {
        let cropView = try XCTUnwrap(cropVC.cropView as? CropView, file: file, line: line)
        let cropBoxView = cropView.cropAuxiliaryIndicatorView
        let cropBox = cropBoxView.frame
        let contentBounds = cropView.getContentBounds()

        XCTAssertEqual(cropView.viewModel.viewStatus, .betweenOperation, file: file, line: line)
        XCTAssertFalse(cropBoxView.isHidden, "crop box is hidden", file: file, line: line)
        XCTAssertGreaterThan(cropBox.width, 0, file: file, line: line)
        XCTAssertGreaterThan(cropBox.height, 0, file: file, line: line)

        // The crop box fits the content bounds: inside, centered, and touching them on one axis.
        assertRect(cropBox, isInside: contentBounds, "crop box outside the content bounds", file: file, line: line)
        XCTAssertEqual(cropBox.midX, contentBounds.midX, accuracy: 0.5, file: file, line: line)
        XCTAssertEqual(cropBox.midY, contentBounds.midY, accuracy: 0.5, file: file, line: line)
        XCTAssertTrue(abs(cropBox.width - contentBounds.width) < 0.5 || abs(cropBox.height - contentBounds.height) < 0.5,
                      "crop box \(cropBox) doesn't fill the content bounds \(contentBounds)", file: file, line: line)

        if let imageContainer = cropView.cropWorkbenchView.imageContainer {
            assertRect(cropBox, isInside: frame(of: imageContainer, in: cropView),
                       "image doesn't cover the crop box", file: file, line: line)
        }

        if let rotationControl = cropView.rotationControlView, rotationControl.isAttachedToCropView {
            XCTAssertFalse(rotationControl.isHidden, "rotation control is hidden", file: file, line: line)
            assertRect(rotationControl.frame, isInside: cropView.bounds,
                       "rotation control outside the crop view", file: file, line: line)
            XCTAssertGreaterThanOrEqual(rotationControl.frame.minY, cropBox.maxY - 0.5,
                                        "rotation control overlaps the crop box", file: file, line: line)
        }

        // Portrait layout: the toolbar sits below the crop view, inside the controller's view.
        let toolbarFrame = frame(of: cropVC.cropToolbar, in: cropVC.view)
        XCTAssertGreaterThanOrEqual(toolbarFrame.minY, frame(of: cropView, in: cropVC.view).maxY - 0.5,
                                    "toolbar overlaps the crop view", file: file, line: line)
        assertRect(toolbarFrame, isInside: cropVC.view.bounds, "toolbar outside the view", file: file, line: line)
    }

    private func frame(of view: UIView, in referenceView: UIView) -> CGRect {
        view.convert(view.bounds, to: referenceView)
    }

    private func assertRect(_ rect: CGRect,
                            isInside container: CGRect,
                            _ message: String,
                            file: StaticString = #filePath,
                            line: UInt = #line) {
        XCTAssertTrue(container.insetBy(dx: -0.5, dy: -0.5).contains(rect), "\(message): \(rect) not in \(container)",
                      file: file, line: line)
    }

    private func assertRect(_ rect: CGRect,
                            equals expected: CGRect,
                            file: StaticString = #filePath,
                            line: UInt = #line) {
        XCTAssertEqual(rect.minX, expected.minX, accuracy: 0.5, file: file, line: line)
        XCTAssertEqual(rect.minY, expected.minY, accuracy: 0.5, file: file, line: line)
        XCTAssertEqual(rect.width, expected.width, accuracy: 0.5, file: file, line: line)
        XCTAssertEqual(rect.height, expected.height, accuracy: 0.5, file: file, line: line)
    }
}
