//
//  TransformDelegate.swift
//  Mantis
//
//  Created by Richard Shane on 21/3/2024.
//

import Foundation

protocol TransformDelegate: AnyObject {
    func undoManager() -> UndoManager
    func isUndoEnabled() -> Bool
    func isRedoEnabled() -> Bool
    func undo()
    func redo()
    func updateCropState(_ cropState: CropState)
    func enableUndo(_ enable: Bool)
    func enableRedo(_ enable: Bool)
    func enableReset(_ enable: Bool)
}

