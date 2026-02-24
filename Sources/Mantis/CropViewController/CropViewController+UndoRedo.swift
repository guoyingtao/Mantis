//
//  CropViewController+UndoRedo.swift
//  Mantis
//
//  Extracted from CropViewController.swift
//

import UIKit

// MARK: - TransformDelegate
extension CropViewController: TransformDelegate {
   
    func updateEnableStateForUndo(_ enable: Bool) {
        if config.enableUndoRedo {
            delegate?.cropViewController(self, didUpdateEnableStateForUndo: enable)
        }
    }
    
    func updateEnableStateForRedo(_ enable: Bool) {
        if config.enableUndoRedo {
            delegate?.cropViewController(self, didUpdateEnableStateForRedo: enable)
        }
    }
    
    func updateEnableStateForReset(_ enable: Bool) {
        if config.enableUndoRedo {
            delegate?.cropViewController(self, didUpdateEnableStateForReset: enable)
        }
    }
    
    func getUndoManager() -> UndoManager {
        return _undoManager
    }
    
    func undo() {
        if config.enableUndoRedo {
            if _undoManager.canUndo {
                _undoManager.undo()
            }
        }
    }
    
    func redo() {
        if config.enableUndoRedo {
            if _undoManager.canRedo {
                _undoManager.redo()
            }
        }
    }
    
    func isRedoEnabled() -> Bool {
        if config.enableUndoRedo {
            return _undoManager.canRedo
        } else {
            return false
        }
    }
    
    func isUndoEnabled() -> Bool {
        if config.enableUndoRedo {
            return _undoManager.canUndo
        } else {
            return false
        }
    }
    
    func updateCropState(_ cropState: CropState) {
        handleTransform(with: cropState)
    }
}
