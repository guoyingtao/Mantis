import UIKit

enum TransformType {
    case resetTransforms
    case transform
}

class TransformRecord: NSObject {
    
    let transformType : TransformType!
    
    public var actionName : String!
        
    let previousValues :  Dictionary<String, Any?>!
    let currentValues : Dictionary<String, Any?>!
    
    var useCurrent : Bool! = true
    
    init(transformType: TransformType, actionName: String, previousValues: [String: Any?], currentValues: [String: Any?]) {
        
        self.transformType = transformType
        self.actionName = actionName
        self.previousValues = previousValues
        self.currentValues = currentValues
        
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateTransformState() {
        let cropState = self.useCurrent ? self.currentValues[.kCurrentTransformState] as! CropState : self.previousValues[.kCurrentTransformState] as! CropState
        
        TransformStack.shared.transformDelegate.updateCropState(cropState)
    }
    
    // Add/Redo
    @objc public func addAdjustmentToStack(_ applyTransform: NSNumber? = nil) {
        
        self.useCurrent = true
        
        if let applyTransform = applyTransform?.boolValue {
            
            if applyTransform {
                self.updateTransformState()
            }
        }
        
        TransformStack.shared.pushTransformRecord(self)
        
        // register the undo event
        TransformStack.shared.transformDelegate.undoManager().registerUndo(withTarget: self, selector: #selector(removeAdjustmentFromStack), object: nil)
        
        TransformStack.shared.transformDelegate.undoManager().setActionName(self.actionName)
        
        TransformStack.shared.transformDelegate.enableReset(self.transformType != .resetTransforms)
    }
    
    // Undo
    @objc public func removeAdjustmentFromStack() {
        
        self.useCurrent = false
        
        self.updateTransformState()
        
        TransformStack.shared.popTransformStack()
        let applyTransform = true
        TransformStack.shared.transformDelegate.undoManager().registerUndo(withTarget: self, selector: #selector(addAdjustmentToStack), object: NSNumber(booleanLiteral: applyTransform))
        
        TransformStack.shared.transformDelegate.undoManager().setActionName(self.actionName)
        
        if self.transformType == .resetTransforms {
            TransformStack.shared.transformDelegate.enableReset(true)
        } else if 0 == TransformStack.shared.top {
            TransformStack.shared.transformDelegate.enableReset(false)
        }
    }
}

extension String {
    public static let kCurrentTransformState = "CurrentTransformState"
}

