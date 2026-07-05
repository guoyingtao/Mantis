import UIKit

enum TransformType {
    case resetTransforms
    case transform
}

class TransformRecord: NSObject {

    /// The stack this record belongs to. Weak because the stack's owner
    /// (`CropViewController`) also owns the `UndoManager` that retains records.
    private weak var stack: TransformStack?

    private let transformType: TransformType

    private let actionName: String

    private let previousValues: [String: CropState]
    private let currentValues: [String: CropState]

    private var useCurrent: Bool = true

    init(stack: TransformStack,
         transformType: TransformType,
         actionName: String,
         previousValues: [String: CropState],
         currentValues: [String: CropState]) {

        self.stack = stack
        self.transformType = transformType
        self.actionName = actionName
        self.previousValues = previousValues
        self.currentValues = currentValues

        super.init()
    }

    func updateTransformState() {
        guard let transformDelegate = stack?.transformDelegate else { return }

        guard let cropState = self.useCurrent ?
                self.currentValues[.kCurrentTransformState]
                : self.previousValues[.kCurrentTransformState] else {
            return
        }

        transformDelegate.updateCropState(cropState)
    }

    // Add/Redo
    @objc func addAdjustmentToStack(_ applyTransform: NSNumber? = nil) {

        guard let stack = stack, let transformDelegate = stack.transformDelegate else { return }

        self.useCurrent = true

        if applyTransform?.boolValue == true {
            updateTransformState()
        }

        stack.pushTransformRecord(self)

        // register the undo event
        transformDelegate.getUndoManager().registerUndo(withTarget: self, selector: #selector(removeAdjustmentFromStack), object: nil)

        transformDelegate.getUndoManager().setActionName(self.actionName)

        transformDelegate.updateEnableStateForReset(self.transformType != .resetTransforms)
    }

    // Undo
    @objc func removeAdjustmentFromStack() {

        guard let stack = stack, let transformDelegate = stack.transformDelegate else { return }

        self.useCurrent = false

        self.updateTransformState()

        stack.popTransformStack()
        let applyTransform = true
        transformDelegate
            .getUndoManager()
            .registerUndo(withTarget: self,
                          selector: #selector(addAdjustmentToStack),
                          object: NSNumber(value: applyTransform))

        transformDelegate.getUndoManager().setActionName(self.actionName)

        if self.transformType == .resetTransforms {
            transformDelegate.updateEnableStateForReset(true)
        } else if 0 == stack.top {
            transformDelegate.updateEnableStateForReset(false)
        }
    }
}

extension String {
    static let kCurrentTransformState = "CurrentTransformState"
}
