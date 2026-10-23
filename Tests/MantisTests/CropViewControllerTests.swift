//
//  CropViewControllerTests.swift
//  MantisTests
//
//  Created by yingtguo on 2/2/23.
//

import XCTest
@testable import Mantis

@MainActor
final class CropViewControllerTests: XCTestCase {
    
    let cropVC = CropViewController()
    let fakeCropView = FakeCropView()
    let fakeCropToolbar = FakeCropToolbar()
    let fakeCropVCDelegate = FakeCropViewControllerDelegate()

    override func setUpWithError() throws {
        cropVC.cropView = fakeCropView
        cropVC.cropToolbar = fakeCropToolbar
        cropVC.delegate = fakeCropVCDelegate
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCropViewDidBecomeResettable() {
        XCTAssertFalse(fakeCropToolbar.didHandleCropViewDidBecomeResettable)
        XCTAssertFalse(fakeCropVCDelegate.didImageTransformed)
        
        cropVC.cropViewDidBecomeResettable(cropVC.cropView)

        XCTAssertTrue(fakeCropToolbar.didHandleCropViewDidBecomeResettable)
        XCTAssertTrue(fakeCropVCDelegate.didImageTransformed)
    }
    
    func testCropViewDidBecomeUnResettable() {
        XCTAssertFalse(fakeCropToolbar.didHandleCropViewDidBecomeUnResettable)
        
        cropVC.cropViewDidBecomeUnResettable(cropVC.cropView)
        
        XCTAssertTrue(fakeCropToolbar.didHandleCropViewDidBecomeUnResettable)
    }
    
    func testCropViewDidBeginResize() {
        XCTAssertFalse(fakeCropVCDelegate.didBeginResize)
        
        cropVC.cropViewDidBeginResize(cropVC.cropView)
        
        XCTAssertTrue(fakeCropVCDelegate.didBeginResize)
    }
    
    func testCropViewDidEndResize() {
        XCTAssertFalse(fakeCropVCDelegate.didEndResize)
        
        cropVC.cropViewDidEndResize(cropVC.cropView)
        
        XCTAssertTrue(fakeCropVCDelegate.didEndResize)
    }
    
    func testCropViewDidBeginCrop() {
        XCTAssertFalse(fakeCropVCDelegate.didBeginCrop)
        
        cropVC.cropViewDidBeginCrop(cropVC.cropView)
        
        XCTAssertTrue(fakeCropVCDelegate.didBeginCrop)
    }
    
    func testCropViewDidEndCrop() {
        XCTAssertFalse(fakeCropVCDelegate.didEndCrop)
        
        cropVC.cropViewDidEndCrop(cropVC.cropView)

        XCTAssertTrue(fakeCropVCDelegate.didEndCrop)
    }

    func testViewWillTransitionWithUnknownOrientationLeavesCropViewUntouched() {
        cropVC.loadViewIfNeeded()
        cropVC.interfaceOrientationProvider = { .unknown }
        let handled = expectation(description: "cropView.handleViewWillTransition() called")
        handled.isInverted = true
        fakeCropView.onHandleViewWillTransition = { handled.fulfill() }

        cropVC.viewWillTransition(to: CGSize(width: 800, height: 400), with: FakeTransitionCoordinator())

        // cropView.prepareForViewWillTransition() hides the crop box and rotation control,
        // so it must only run on the path that also calls cropView.handleViewWillTransition().
        XCTAssertEqual(fakeCropView.prepareForViewWillTransitionCallCount, 0)
        // cropView.handleViewWillTransition() is dispatched after 0.1 s, so wait past that.
        wait(for: [handled], timeout: 0.3)
    }

    func testViewWillTransitionToPortraitUpsideDownPreparesThenRestoresCropView() {
        cropVC.loadViewIfNeeded()
        cropVC.interfaceOrientationProvider = { .portraitUpsideDown }
        let handled = expectation(description: "cropView.handleViewWillTransition() called")
        fakeCropView.onHandleViewWillTransition = { handled.fulfill() }

        cropVC.viewWillTransition(to: CGSize(width: 400, height: 800), with: FakeTransitionCoordinator())

        XCTAssertEqual(fakeCropView.prepareForViewWillTransitionCallCount, 1)
        wait(for: [handled], timeout: 1)
        XCTAssertEqual(fakeCropView.handleViewWillTransitionCallCount, 1)
    }
}

// Lets tests call viewWillTransition(to:with:) directly. Defined here rather than
// in Mock/ so the Xcode project file doesn't need a new entry.
private final class FakeTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {
    var isAnimated: Bool { false }
    var presentationStyle: UIModalPresentationStyle { .none }
    var initiallyInteractive: Bool { false }
    var isInterruptible: Bool { false }
    var isInteractive: Bool { false }
    var isCancelled: Bool { false }
    var transitionDuration: TimeInterval { 0 }
    var percentComplete: CGFloat { 1 }
    var completionVelocity: CGFloat { 1 }
    var completionCurve: UIView.AnimationCurve { .linear }
    var containerView: UIView { UIView() }
    var targetTransform: CGAffineTransform { .identity }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? { nil }
    func view(forKey key: UITransitionContextViewKey) -> UIView? { nil }

    func animate(alongsideTransition animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
                 completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)?) -> Bool {
        false
    }

    func animateAlongsideTransition(in view: UIView?,
                                    animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
                                    completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)?) -> Bool {
        false
    }

    func notifyWhenInteractionEnds(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {}

    func notifyWhenInteractionChanges(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {}
}
