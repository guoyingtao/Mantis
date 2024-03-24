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

    var image: UIImage?
    var cropViewController: CropViewController?
    
    var didGetCroppedImage: ((UIImage) -> Void)?
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var resolutionLabel: UILabel!
    
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var redoButton: UIBarButtonItem!
    @IBOutlet weak var resetButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        cropViewController?.didSelectUndo()
    }
    
    @IBAction func redoButtonPressed(_ sender: Any) {
        cropViewController?.didSelectRedo()
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
        config.enableUndoRedo = true
        
        config.cropToolbarConfig.toolbarButtonOptions = [.counterclockwiseRotate, .clockwiseRotate, .horizontallyFlip, .verticallyFlip]
        
        Mantis.setupCropViewController(cropViewController, with: image, and: config)
        
        self.cropViewController = cropViewController
    }
    
    private func getResolution(image: UIImage?) -> String? {
        if let size = image?.size {
            return "\(Int(size.width)) x \(Int(size.height)) pixels"
        }
        return nil
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        if action == #selector(EmbeddedCropViewController.undoButtonPressed(_:)) ||
           action == #selector(EmbeddedCropViewController.redoButtonPressed(_:))  ||
           action == #selector(EmbeddedCropViewController.resetButtonPressed(_:)) {
            
            return cropViewController!.isUndoSupported()
        }
        
        return true
    }
    
    override func validate(_ command: UICommand) {
        
        guard let cropViewController else { return }
        
        if cropViewController.isUndoSupported() {
           
            if command.action == #selector(EmbeddedCropViewController.undoButtonPressed(_:)) {
                
                let undoString = NSLocalizedString("Undo", comment: "Undo")
                
                command.title = self.undoButton.isEnabled ? "\(undoString) \(cropViewController.undoActionName())" : undoString
                
                if !self.undoButton.isEnabled {
                    command.attributes = [.disabled]
                }
            }
            
            if command.action == #selector(EmbeddedCropViewController.redoButtonPressed(_:)) {
                
                let redoString = NSLocalizedString("Redo", comment: "Redo")
                
                command.title = self.redoButton.isEnabled ? "\(redoString) \(cropViewController.redoActionName())" : redoString
                
                if !self.redoButton.isEnabled {
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

}

extension EmbeddedCropViewController: CropViewControllerDelegate {
    
    func cropViewController(_ cropViewController: CropViewController, didUpdateEnableStateForUndo enable: Bool) {
        self.undoButton.isEnabled = enable
    }
    
    func cropViewController(_ cropViewController: CropViewController, didUpdateEnableStateForRedo enable: Bool) {
        self.redoButton.isEnabled = enable
    }
    
    func cropViewController(_ cropViewController: CropViewController, didUpdateEnableStateForReset enable: Bool) {
        self.resetButton.isEnabled = enable
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

