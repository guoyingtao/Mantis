//
//  EmbeddedCropViewController.swift
//  MantisExample
//
//  Created by Yingtao Guo on 11/9/18.
//  Copyright © 2018 Echo Studio. All rights reserved.
//

import UIKit
import Mantis

class EmbeddedCropViewController: UIViewController {

    let _undoManager : UndoManager! = UndoManager()
    
    var image: UIImage?
    var cropViewController: CropViewController?
    
    weak var toolbarDelegate: CropToolbarDelegate?
    
    
    var didGetCroppedImage: ((UIImage) -> Void)?
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var resolutionLabel: UILabel!
    
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var redoButton: UIBarButtonItem!
    @IBOutlet weak var resetButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TransformStack.shared.sharedTransformDelegate = self
        undoButton.title = "Undo"
        redoButton.title = "Redo"
        cancelButton.title = "Cancel"
        doneButton.title = "Done"
        resetButton.title = "Revert"
        
        resolutionLabel.text = "\(getResolution(image: image) ?? "unknown")"
        
        view.backgroundColor = .black
        navigationController?.toolbar.backgroundColor = .black
        
        self.undoButton.isEnabled = false
        self.redoButton.isEnabled = false
        self.resetButton.isEnabled = false
    }
    
    @IBAction func undoButtonPressed(_ sender: Any) {
        undo()
    }
    
    @IBAction func redoButtonPressed(_ sender: Any) {
        redo()
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        cropViewController?.didSelectReset()
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func crop(_ sender: Any) {
        cropViewController?.crop()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let cropViewController = segue.destination as? CropViewController, let image = image else {
            return
        }
        
        cropViewController.delegate = self
                    
        var config = Mantis.Config()
        config.cropToolbarConfig.mode = .embedded
        
        config.cropToolbarConfig.toolbarButtonOptions = [.counterclockwiseRotate, .clockwiseRotate, .horizontallyFlip, .verticallyFlip]
        
        Mantis.setupCropViewController(cropViewController, with: image, and: config)
        
        self.cropViewController = cropViewController
        self.toolbarDelegate = cropViewController
    }
    
    private func getResolution(image: UIImage?) -> String? {
        if let size = image?.size {
            return "\(Int(size.width)) x \(Int(size.height)) pixels"
        }
        return nil
    }
    
    override func validate(_ command: UICommand) {
        
        if command.action == #selector(EmbeddedCropViewController.undoButtonPressed(_:)) {
            
            let undoString = NSLocalizedString("Undo", comment: "Undo")
            
            command.title = self._undoManager.canUndo ? "\(undoString) \(self._undoManager.undoActionName)" : undoString
            
            if !self._undoManager.canUndo {
                command.attributes = [.disabled]
            }
        }
        
        if command.action == #selector(EmbeddedCropViewController.redoButtonPressed(_:)) {
            
            let redoString = NSLocalizedString("Redo", comment: "Redo")
            
            command.title = self._undoManager.canRedo ? "\(redoString) \(self._undoManager.redoActionName)" : redoString
            
            if !self._undoManager.canRedo {
                command.attributes = [.disabled]
            }
            
        }
        
        if command.action == #selector(EmbeddedCropViewController.resetButtonPressed(_:)) {
                        
            command.title = NSLocalizedString("Revert to Original", comment: "Revert to Original")
            
            if !self.resetButton.isEnabled {
                command.attributes = [.disabled]
            }
        }
    }
}

extension EmbeddedCropViewController: CropViewControllerDelegate {
    
    func cropViewControllerDidReset(previous: CropState, current: CropState) {
        
        let actionString = NSLocalizedString("Reset Changes", comment: "Reset Changes")
        
        let previousValue :  [String : Any?] = [.kCurrentTransformState : previous]
        let currentValue :  [String : Any?] = [.kCurrentTransformState : current]
        
        let transformRecord = TransformRecord(transformType: .resetTransforms, actionName: actionString, previousValues: previousValue, currentValues: currentValue)
        
        transformRecord.addAdjustmentToStack()
    }
    
    func cropViewControllerDidTransformImage(previous: Mantis.CropState, current: Mantis.CropState, userGenerated: Bool) {
        
        if userGenerated {
            let actionString = NSLocalizedString("Change Crop", comment: "Change Crop")
            
            let previousValue :  [String : Any?] = [.kCurrentTransformState : previous]
            let currentValue :  [String : Any?] = [.kCurrentTransformState : current]
            
            let transformRecord = TransformRecord(transformType: .transform, actionName: actionString, previousValues: previousValue, currentValues: currentValue)
            
            transformRecord.addAdjustmentToStack()
        }
    }
    
    func cropViewControllerDidCrop(_ cropViewController: CropViewController,
                                   cropped: UIImage,
                                   transformation: Transformation,
                                   cropInfo: CropInfo) {
        self.dismiss(animated: true)
        self.didGetCroppedImage?(cropped)
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        self.dismiss(animated: true)
    }
    
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {
        self.resolutionLabel.text = "..."
    }
    
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {
        let size = cropViewController.getExpectedCropImageSize()
        self.resolutionLabel.text = "\(Int(size.width)) x \(Int(size.height)) pixels"
    }

}

extension EmbeddedCropViewController: TransformDelegate {
    
    func enableReset(_ enable: Bool) {
        self.resetButton.isEnabled = enable
    }
    
    func undoManager() -> UndoManager {
        return _undoManager
    }
    
    func isUndoing() -> Bool {
        return true
    }
    
    func isRedoing() -> Bool {
        return true
    }
    
    func undo() {
        
        // Change State
        if _undoManager.canUndo {
            
            _undoManager.undo()
        }
    }
    
    func redo() {
        
        // Change State
        if _undoManager.canRedo {
                        
            _undoManager.redo()
        }
    }
    
    func isRedoEnabled() -> Bool {
        return _undoManager.canRedo
    }
    
    func isUndoEnabled() -> Bool {
        return _undoManager.canUndo
    }
    
    func updateCropState(_ cropState: Any) {
        guard let cropState = cropState as? CropState else { return }
        toolbarDelegate?.didSelectTransform(with: cropState)
    }
}
