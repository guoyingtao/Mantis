//
//  CropViewController+ToolbarDelegate.swift
//  Mantis
//
//  Extracted from CropViewController.swift
//

import UIKit

// MARK: - CropToolbarDelegate
extension CropViewController: CropToolbarDelegate {
    
    public func didSelectUndo() {
        undo()
    }
    
    public func didSelectRedo() {
        redo()
    }
    
    public func undoActionName() -> String {
        return _undoManager.undoActionName
    }
    
    public func redoActionName() -> String {
        return _undoManager.redoActionName
    }
    
    public func isUndoSupported() -> Bool {
        return config.enableUndoRedo
    }
    
    public func didSelectHorizontallyFlip(_ cropToolbar: CropToolbarProtocol? = nil) {
        savePreviousCropStateIfNeeded()
        handleHorizontallyFlip()
    }
    
    public func didSelectVerticallyFlip(_ cropToolbar: CropToolbarProtocol? = nil) {
        savePreviousCropStateIfNeeded()
        handleVerticallyFlip()
    }
    
    public func didSelectCancel(_ cropToolbar: CropToolbarProtocol? = nil) {
        handleCancel()
    }
    
    public func didSelectCrop(_ cropToolbar: CropToolbarProtocol? = nil) {
        handleCrop()
    }
    
    public func didSelectCounterClockwiseRotate(_ cropToolbar: CropToolbarProtocol? = nil) {
        savePreviousCropStateIfNeeded()
        handleRotate(withRotateType: .counterClockwise)
    }
    
    public func didSelectClockwiseRotate(_ cropToolbar: CropToolbarProtocol? = nil) {
        savePreviousCropStateIfNeeded()
        handleRotate(withRotateType: .clockwise)
    }
    
    public func didSelectReset(_ cropToolbar: CropToolbarProtocol? = nil) {
        handleReset()
    }
    
    public func didSelectSetRatio(_ cropToolbar: CropToolbarProtocol? = nil) {
        savePreviousCropStateIfNeeded()
        handleSetRatio()
    }
    
    public func didSelectRatio(_ cropToolbar: CropToolbarProtocol? = nil, ratio: Double) {
        savePreviousCropStateIfNeeded()
        setFixedRatio(ratio)
    }
    
    public func didSelectFreeRatio(_ cropToolbar: CropToolbarProtocol? = nil) {
        savePreviousCropStateIfNeeded()
        setFreeRatio()
    }
    
    public func didSelectAlterCropper90Degree(_ cropToolbar: CropToolbarProtocol? = nil) {
        handleAlterCropper90Degree()
    }
    
    public func didSelectAutoAdjust(_ cropToolbar: CropToolbarProtocol?, isActive: Bool) {
        handleAutoAdjust(isActive: isActive)
    }
}
