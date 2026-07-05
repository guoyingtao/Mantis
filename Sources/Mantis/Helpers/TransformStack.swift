import UIKit

/// A per-crop-session undo/redo bookkeeping stack.
///
/// Each `CropViewController` owns its own instance, so multiple concurrent
/// crop sessions (e.g. two windows on iPad) never pollute each other's
/// undo history.
class TransformStack: NSObject {

    weak var transformDelegate: TransformDelegate? {
        didSet {
            NotificationCenter.default.removeObserver(self, name: .NSUndoManagerCheckpoint, object: nil)
            if let transformDelegate = transformDelegate {
                // Observe only this session's undo manager so checkpoints from
                // other concurrent crop sessions don't trigger this stack.
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.undoStatusChanged(notification:)),
                    name: .NSUndoManagerCheckpoint,
                    object: transformDelegate.getUndoManager())
            }
        }
    }

    private var transformAdjustmentsStack: [TransformRecord] = []

    var top: Int = 0

    func pushTransformRecord(_ record: TransformRecord) {
        if transformAdjustmentsStack.count > top {
            transformAdjustmentsStack.remove(at: top)
        }
        transformAdjustmentsStack.insert(record, at: top)
        top += 1
    }

    func popTransformStack() {
        if top > 0 {
            top -= 1
        }
    }

    func reset() {
        transformAdjustmentsStack.removeAll()
        top = 0
    }

    @objc func undoStatusChanged(notification: NSNotification?) {
        guard let transformDelegate = transformDelegate else { return }
        transformDelegate.updateEnableStateForUndo(transformDelegate.isUndoEnabled())
        transformDelegate.updateEnableStateForRedo(transformDelegate.isRedoEnabled())
    }

    func pushTransformRecordOntoStack(transformType: TransformType, previous: CropState, current: CropState, userGenerated: Bool) {
        if userGenerated {

            let actionString: String

            switch transformType {
            case .transform:
                actionString = LocalizedHelper.getString("Mantis.ChangeCrop", value: "Change Crop")
            case .resetTransforms:
                actionString = LocalizedHelper.getString("Mantis.ResetChanges", value: "Reset Changes")
            }

            let previousValue: [String: CropState] = [.kCurrentTransformState: previous]
            let currentValue: [String: CropState] = [.kCurrentTransformState: current]

            let transformRecord = TransformRecord(stack: self,
                                                  transformType: transformType,
                                                  actionName: actionString,
                                                  previousValues: previousValue,
                                                  currentValues: currentValue)

            transformRecord.addAdjustmentToStack()
        }
    }
}
