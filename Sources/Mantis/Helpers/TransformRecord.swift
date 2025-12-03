import UIKit

enum TransformType {
    case resetTransforms
    case transform
}

class TransformRecord: NSObject {
    
    private let transformType: TransformType
    
    private let actionName: String
    
    private let previousValues: [String: CropState]
    private let currentValues: [String: CropState]
    
    private var useCurrent: Bool = true
    
    init(transformType: TransformType, actionName: String, previousValues: [String: CropState], currentValues: [String: CropState]) {
        
        self.transformType = transformType
        self.actionName = actionName
        self.previousValues = previousValues
        self.currentValues = currentValues
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTransformState() {
        guard let transformDelegate = TransformStack.shared.transformDelegate else { return }

        guard let cropState = self.useCurrent ?
                self.currentValues[.kCurrentTransformState]
                : self.previousValues[.kCurrentTransformState] else {
            return
        }
        
        transformDelegate.updateCropState(cropState)
    }
    
    // Add/Redo
    @objc func addAdjustmentToStack(_ applyTransform: NSNumber? = nil) {
        
        guard let transformDelegate = TransformStack.shared.transformDelegate else { return }
        
        self.useCurrent = true
        
        if applyTransform?.boolValue == true {
            updateTransformState()
        }
        
        TransformStack.shared.pushTransformRecord(self)
        
        // register the undo event
        transformDelegate.getUndoManager().registerUndo(withTarget: self, selector: #selector(removeAdjustmentFromStack), object: nil)
        
        transformDelegate.getUndoManager().setActionName(self.actionName)
        
        transformDelegate.updateEnableStateForReset(self.transformType != .resetTransforms)
    }
    
    // Undo
    @objc func removeAdjustmentFromStack() {
        
        guard let transformDelegate = TransformStack.shared.transformDelegate else { return }
        
        self.useCurrent = false
        
        self.updateTransformState()
        
        TransformStack.shared.popTransformStack()
        let applyTransform = true
        transformDelegate
            .getUndoManager()
            .registerUndo(withTarget: self,
                          selector: #selector(addAdjustmentToStack),
                          object: NSNumber(value: applyTransform))
        
        transformDelegate.getUndoManager().setActionName(self.actionName)
        
        if self.transformType == .resetTransforms {
            transformDelegate.updateEnableStateForReset(true)
        } else if 0 == TransformStack.shared.top {
            transformDelegate.updateEnableStateForReset(false)
        }
    }
}

extension String {
    static let kCurrentTransformState = "CurrentTransformState"
}
