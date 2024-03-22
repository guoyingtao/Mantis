import UIKit


class TransformStack: NSObject {
    
    static var shared: TransformStack = TransformStack()
    
    weak var transformDelegate : TransformDelegate?
    
    private var transformAdjustmentsStack: [TransformRecord] = []
    
    private var isRotated: Bool = false
    
    private var bottom: Int = 0
    
    var top: Int = 0
    
    private var transformStackBottom: Int = 0
    private var transformStackTop: Int = 0
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override init() {
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
        guard let transformDelegate = transformDelegate else { return }
        transformDelegate.updateEnableStateForUndo(transformDelegate.isUndoEnabled())
        transformDelegate.updateEnableStateForRedo(transformDelegate.isRedoEnabled())
    }
}
