import UIKit

enum TransformType {
    case resetTransforms
    case transform
}

class TransformRecord: NSObject {
    
    private let transformType: TransformType
    
    private let actionName: String
    
    private let previousValues:  Dictionary<String, CropState>
    private let currentValues: Dictionary<String, CropState>
    
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
        guard let cropState = self.useCurrent ? self.currentValues[.kCurrentTransformState] : self.previousValues[.kCurrentTransformState] else { return }
        
        TransformStack.shared.transformDelegate.updateCropState(cropState)
    }
    
    // Add/Redo
    @objc func addAdjustmentToStack(_ applyTransform: NSNumber? = nil) {
        
        self.useCurrent = true
        
        if let applyTransform = applyTransform?.boolValue {
            
            if applyTransform {
                self.updateTransformState()
            }
        }
        
        TransformStack.shared.pushTransformRecord(self)
        
        // register the undo event
        TransformStack.shared.transformDelegate.getUndoManager().registerUndo(withTarget: self, selector: #selector(removeAdjustmentFromStack), object: nil)
        
        TransformStack.shared.transformDelegate.getUndoManager().setActionName(self.actionName)
        
        TransformStack.shared.transformDelegate.updateEnableStateForReset(self.transformType != .resetTransforms)
    }
    
    // Undo
    @objc func removeAdjustmentFromStack() {
        
        self.useCurrent = false
        
        self.updateTransformState()
        
        TransformStack.shared.popTransformStack()
        let applyTransform = true
        TransformStack.shared.transformDelegate.getUndoManager().registerUndo(withTarget: self, selector: #selector(addAdjustmentToStack), object: NSNumber(booleanLiteral: applyTransform))
        
        TransformStack.shared.transformDelegate.getUndoManager().setActionName(self.actionName)
        
        if self.transformType == .resetTransforms {
            TransformStack.shared.transformDelegate.updateEnableStateForReset(true)
        } else if 0 == TransformStack.shared.top {
            TransformStack.shared.transformDelegate.updateEnableStateForReset(false)
        }
    }
}

extension String {
    static let kCurrentTransformState = "CurrentTransformState"
}

