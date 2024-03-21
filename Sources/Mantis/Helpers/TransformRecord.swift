import UIKit

public enum TransformType: Int {
    case resetTransforms
    case transform
}

public protocol TransformDelegate : AnyObject {
    
    var undoButton: UIBarButtonItem! { get set }
    var redoButton: UIBarButtonItem! { get set }
    var resetButton: UIBarButtonItem! { get set }
    
    func undoManager() -> UndoManager
    func isUndoEnabled() -> Bool
    func isRedoEnabled() -> Bool
    func isUndoing() -> Bool
    func isRedoing() -> Bool
    func undo()
    func redo()
    func updateCropState(_ cropState: Any)
    func enableResetButton(_ enable: Bool)
}

public class TransformRecord: NSObject {
    
    let transformType : TransformType!
   
    public var actionName : String!

    var useCurrent : Bool! = true

    let previousValues :  Dictionary<String, Any?>!
    var currentValues : Dictionary<String, Any?>!
    
    public init(transformType: TransformType, actionName: String, previousValues: [String : Any?], currentValues: [String : Any?]) {
        
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
            
        TransformStack.shared.sharedTransformDelegate.updateCropState(cropState)
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
        TransformStack.shared.sharedTransformDelegate.undoManager().registerUndo(withTarget: self, selector: #selector(removeAdjustmentFromStack), object: nil)
        
        TransformStack.shared.sharedTransformDelegate.undoManager().setActionName(self.actionName)
        
        TransformStack.shared.sharedTransformDelegate.enableResetButton(self.transformType != .resetTransforms)
    }
    
    // Undo
     @objc public func removeAdjustmentFromStack() {
        
         self.useCurrent = false
         
         self.updateTransformState()
         
         TransformStack.shared.popTransformStack()
         let applyTransform = true
         TransformStack.shared.sharedTransformDelegate.undoManager().registerUndo(withTarget: self, selector: #selector(addAdjustmentToStack), object: NSNumber(booleanLiteral: applyTransform))
        
         TransformStack.shared.sharedTransformDelegate.undoManager().setActionName(self.actionName)
         
         if self.transformType == .resetTransforms {
             TransformStack.shared.sharedTransformDelegate.enableResetButton(true)
         } else if 0 == TransformStack.shared.top {
             TransformStack.shared.sharedTransformDelegate.enableResetButton(false)
         }
    }
}

extension String {
    public static let kCurrentTransformState = "CurrentTransformState"
}

