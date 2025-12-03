//
//  TransformDelegate.swift
//  Mantis
//
//  Created by Richard Shane on 21/3/2024.
//

import Foundation

protocol TransformDelegate: AnyObject {
    func getUndoManager() -> UndoManager
    func isUndoEnabled() -> Bool
    func isRedoEnabled() -> Bool
    func undo()
    func redo()
    func updateCropState(_ cropState: CropState)
    func updateEnableStateForUndo(_ enable: Bool)
    func updateEnableStateForRedo(_ enable: Bool)
    func updateEnableStateForReset(_ enable: Bool)
}
