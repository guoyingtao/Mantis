//
//  TransformRecordTests.swift
//  MantisTests
//
//  Covers the undo/redo bookkeeping in TransformRecord: which stored crop
//  state (current vs previous) is pushed to the delegate on redo vs undo, the
//  applyTransform gate that decides whether the state is applied at all, stack
//  push/pop, and the reset-button enable logic that depends on the transform
//  type and the stack depth.
//

import XCTest
@testable import Mantis

private final class FakeTransformDelegate: TransformDelegate {
    let undoManager = UndoManager()
    var updatedCropStates: [CropState] = []
    var resetEnableStates: [Bool] = []
    var undoEnableStates: [Bool] = []
    var redoEnableStates: [Bool] = []

    func getUndoManager() -> UndoManager { undoManager }
    func isUndoEnabled() -> Bool { undoManager.canUndo }
    func isRedoEnabled() -> Bool { undoManager.canRedo }
    func undo() {}
    func redo() {}
    func updateCropState(_ cropState: CropState) { updatedCropStates.append(cropState) }
    func updateEnableStateForUndo(_ enable: Bool) { undoEnableStates.append(enable) }
    func updateEnableStateForRedo(_ enable: Bool) { redoEnableStates.append(enable) }
    func updateEnableStateForReset(_ enable: Bool) { resetEnableStates.append(enable) }
}

final class TransformRecordTests: XCTestCase {

    private var stack: TransformStack!
    private var delegate: FakeTransformDelegate!

    override func setUp() {
        super.setUp()
        stack = TransformStack()
        delegate = FakeTransformDelegate()
        stack.transformDelegate = delegate
    }

    override func tearDown() {
        stack = nil
        delegate = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    private func makeTransformation() -> Transformation {
        Transformation(offset: .zero,
                       rotation: 0,
                       scale: 1,
                       isManuallyZoomed: false,
                       initialMaskFrame: .zero,
                       maskFrame: .zero,
                       cropWorkbenchViewBounds: .zero,
                       horizontallyFlipped: false,
                       verticallyFlipped: false)
    }

    /// A CropState distinguished purely by `degrees`, so tests can tell the
    /// "previous" and "current" states apart.
    private func makeCropState(degrees: CGFloat) -> CropState {
        CropState(rotationType: .none,
                  degrees: degrees,
                  aspectRatioLockEnabled: false,
                  aspectRato: 1,
                  flipOddTimes: false,
                  transformation: makeTransformation(),
                  horizontalSkewDegrees: 0,
                  verticalSkewDegrees: 0)
    }

    private func makeRecord(type: TransformType,
                            previousDegrees: CGFloat,
                            currentDegrees: CGFloat) -> TransformRecord {
        TransformRecord(stack: stack,
                        transformType: type,
                        actionName: "Test",
                        previousValues: [.kCurrentTransformState: makeCropState(degrees: previousDegrees)],
                        currentValues: [.kCurrentTransformState: makeCropState(degrees: currentDegrees)])
    }

    // MARK: - Redo (addAdjustmentToStack)

    func testAddAppliesCurrentStateWhenApplyTransformTrue() {
        let record = makeRecord(type: .transform, previousDegrees: 10, currentDegrees: 20)
        record.addAdjustmentToStack(NSNumber(value: true))

        XCTAssertEqual(delegate.updatedCropStates.count, 1)
        XCTAssertEqual(delegate.updatedCropStates.first?.degrees, 20) // the "current" state
        XCTAssertEqual(stack.top, 1)
    }

    func testAddDoesNotApplyStateWhenApplyTransformOmitted() {
        let record = makeRecord(type: .transform, previousDegrees: 10, currentDegrees: 20)
        record.addAdjustmentToStack()

        XCTAssertTrue(delegate.updatedCropStates.isEmpty)
        XCTAssertEqual(stack.top, 1) // still pushed onto the stack
    }

    func testAddRegistersUndo() {
        let record = makeRecord(type: .transform, previousDegrees: 10, currentDegrees: 20)
        record.addAdjustmentToStack(NSNumber(value: true))
        XCTAssertTrue(delegate.undoManager.canUndo)
    }

    func testAddEnablesResetForNormalTransform() {
        let record = makeRecord(type: .transform, previousDegrees: 10, currentDegrees: 20)
        record.addAdjustmentToStack(NSNumber(value: true))
        XCTAssertEqual(delegate.resetEnableStates.last, true)
    }

    func testAddDisablesResetForResetTransform() {
        let record = makeRecord(type: .resetTransforms, previousDegrees: 10, currentDegrees: 20)
        record.addAdjustmentToStack(NSNumber(value: true))
        XCTAssertEqual(delegate.resetEnableStates.last, false)
    }

    func testAddIsNoOpWithoutDelegate() {
        stack.transformDelegate = nil
        let record = makeRecord(type: .transform, previousDegrees: 10, currentDegrees: 20)
        record.addAdjustmentToStack(NSNumber(value: true))
        XCTAssertEqual(stack.top, 0)
        XCTAssertTrue(delegate.updatedCropStates.isEmpty)
    }

    // MARK: - Undo (removeAdjustmentFromStack)

    func testUndoAppliesPreviousStateAndPopsStack() {
        let record = makeRecord(type: .transform, previousDegrees: 10, currentDegrees: 20)
        record.addAdjustmentToStack(NSNumber(value: true))
        XCTAssertEqual(stack.top, 1)

        record.removeAdjustmentFromStack()

        // The most recent state pushed to the delegate is the "previous" one.
        XCTAssertEqual(delegate.updatedCropStates.last?.degrees, 10)
        XCTAssertEqual(stack.top, 0)
    }

    func testUndoDisablesResetWhenStackReturnsToBottom() {
        let record = makeRecord(type: .transform, previousDegrees: 10, currentDegrees: 20)
        record.addAdjustmentToStack(NSNumber(value: true))
        record.removeAdjustmentFromStack()
        // Back at the bottom of a normal-transform stack => reset disabled.
        XCTAssertEqual(delegate.resetEnableStates.last, false)
    }

    func testUndoEnablesResetForResetTransform() {
        let record = makeRecord(type: .resetTransforms, previousDegrees: 10, currentDegrees: 20)
        record.addAdjustmentToStack(NSNumber(value: true))
        record.removeAdjustmentFromStack()
        XCTAssertEqual(delegate.resetEnableStates.last, true)
    }

    func testUndoAboveBottomDoesNotTouchResetState() {
        let first = makeRecord(type: .transform, previousDegrees: 1, currentDegrees: 2)
        let second = makeRecord(type: .transform, previousDegrees: 3, currentDegrees: 4)
        first.addAdjustmentToStack(NSNumber(value: true))
        second.addAdjustmentToStack(NSNumber(value: true))
        XCTAssertEqual(stack.top, 2)

        let resetCallsBefore = delegate.resetEnableStates.count
        second.removeAdjustmentFromStack()

        // Still above the bottom (top == 1) and not a reset transform, so the
        // reset-enable state is left untouched.
        XCTAssertEqual(stack.top, 1)
        XCTAssertEqual(delegate.resetEnableStates.count, resetCallsBefore)
    }
}
