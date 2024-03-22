import UIKit


class TransformStack: NSObject {
    
    static var shared: TransformStack = TransformStack()
    
    weak var transformDelegate : TransformDelegate!
    
    var transformAdjustmentsStack : Array = [TransformRecord]()
    
    var isRotated : Bool! = false
    
    var bottom : Int = 0
    var top : Int = 0
    
    var transformStackBottom : Int = 0
    var transformStackTop : Int = 0
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.undoStatusChanged(notification:)),
            name: .NSUndoManagerCheckpoint,
            object: nil)
    }
    
    func pushTransformRecord(_ record: TransformRecord) {
        if transformAdjustmentsStack.count > top {
            transformAdjustmentsStack.remove(at: top)
        }
        transformAdjustmentsStack.insert(record, at: top)
        top += 1
    }

    func popTransformStack() {
        top -= 1
    }
    
    func reset() {
        transformAdjustmentsStack.removeAll()
        top = 0
        bottom = 0
        isRotated = false
    }
    
    @objc func undoStatusChanged(notification: NSNotification?) {
        transformDelegate.enableUndo(transformDelegate.isUndoEnabled())
        transformDelegate.enableRedo(transformDelegate.isRedoEnabled())
    }
}
