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
    
    var adjustmentModeMenu: UIMenu!

    var image: UIImage?
    var cropViewController: CropViewController?
    
    var didGetCroppedImage: ((UIImage) -> Void)?
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var resolutionLabel: UILabel!
    
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var redoButton: UIBarButtonItem!
    @IBOutlet weak var resetButton: UIBarButtonItem!
    
    
    @IBOutlet weak var straightenModeButton: UIBarButtonItem!
    
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
        
        self.adjustmentModeMenu = createStraightenAdjustmentModeMenu()
        if #available(macCatalyst 14.0, *) {
            if #available(iOS 14.0, *) {
                self.straightenModeButton.menu = self.adjustmentModeMenu
            } else {
                // Fallback on earlier versions
            }
            //self.straightenModeButton.showsMenuAsPrimaryAction = true
            self.straightenModeButton.tintColor = .white
            //self.straightenModeButton.contentMode = .scaleAspectFit
            //self.straightenModeButton.imageView?.contentMode = .scaleAspectFit
        } else {
            // Fallback on earlier versions
        }
        
        self.straightenModeButton.image = StraightenAdjustmentMode.straighten.buttonIcon
       
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
    
    @IBAction func updateImage(_ sender: Any) {
        guard let image else {
            return
        }
        
        cropViewController?.update(image.addFilter(filter: .Mono))
    }
    
    func createStraightenAdjustmentModeMenu() -> UIMenu? {
        let adjustmentModeItems: [StraightenAdjustmentMode] = StraightenAdjustmentMode.allCases
        
        var actions: [UIAction] = []
       
        let imageConfiguration: UIImage.SymbolConfiguration = UIImage.SymbolConfiguration(scale: .large)
        
        for mode in adjustmentModeItems {
            
            // Show/Hide Control Panel While Scrolling (Localize)
            let actionString = mode.description
            
            let actionImage = mode.menuIcon?.withConfiguration(imageConfiguration)
            
            let action: UIAction = UIAction(title: actionString, image: actionImage, identifier: nil) { [self] action in
                
                didSelectAdjustmentMode(mode)
            }
            
            actions.append(action)
        }
        
        actions[0].state = .on
        if #available(macCatalyst 15.0, *) {
            if #available(iOS 15.0, *) {
                let adjustmentModeMenu: UIMenu = UIMenu(title: "", image: nil, identifier: nil, options: .singleSelection, children: actions)

                return adjustmentModeMenu

            } else {
                // Fallback on earlier versions
                return nil
            }
            

        } else {
            // Fallback on earlier versions
            let adjustmentModeMenu: UIMenu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
            
            return adjustmentModeMenu

        }
        
    }
    
    func didSelectAdjustmentMode(_ mode: StraightenAdjustmentMode) {
        
        //self.rotateButtonGroupView.isHidden = (mode != .straighten)
        let icon = mode.buttonIcon
        self.straightenModeButton.image = icon
        
//        guard StraightenAdjustmentMode(rawValue: mode.rawValue) != nil else { return }
        
        cropViewController?.setRotationAdjustmentType(RotationAdjustmentType(rawValue: mode.rawValue)!)
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

enum FilterType : String {
    case Chrome = "CIPhotoEffectChrome"
    case Fade = "CIPhotoEffectFade"
    case Instant = "CIPhotoEffectInstant"
    case Mono = "CIPhotoEffectMono"
    case Noir = "CIPhotoEffectNoir"
    case Process = "CIPhotoEffectProcess"
    case Tonal = "CIPhotoEffectTonal"
    case Transfer = "CIPhotoEffectTransfer"
}

extension UIImage {
    func addFilter(filter : FilterType) -> UIImage {
        let filter = CIFilter(name: filter.rawValue)
        // convert UIImage to CIImage and set as input
        let ciInput = CIImage(image: self)
        filter?.setValue(ciInput, forKey: "inputImage")
        // get output CIImage, render as CGImage first to retain proper UIImage scale
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        //Return the image
        return UIImage(cgImage: cgImage!)
    }
    
    func rotate(radians: Float, flipHorizontal: Bool = false, flipVertical: Bool = false) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        
        let xScale: CGFloat = flipHorizontal ? -1 : 1.0
        let yScale: CGFloat = flipVertical ? -1 : 1.0
        
        context.scaleBy(x: xScale, y: yScale)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
    
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

enum StraightenAdjustmentMode: Int, CaseIterable {
    
    case straighten
    case horizontalPerspective
    case verticalPerspective
    
    var description: String {
        switch self {
        case .straighten:
            return NSLocalizedString("Straighten", comment: "Straighten")
        case .horizontalPerspective:
            return NSLocalizedString("Horizontal Perspective", comment: "Horizontal Perspective")
        case .verticalPerspective:
            return NSLocalizedString("Vertical Perspective", comment: "Vertical Perspective")
            
        }
    }
    
    var menuIcon: UIImage? {
        
        var image: UIImage? = nil
        
        switch self {
        case .straighten:
            image = UIImage(systemName: "rectangle.slash")?.rotate(radians: -.pi/4, flipHorizontal: true)
        case .horizontalPerspective:
            image = UIImage(systemName: "perspective")?.rotate(radians: .pi)
        case .verticalPerspective:
            image = UIImage(systemName: "perspective")?.rotate(radians: -.pi/2)
        }
        return image?.withRenderingMode(.alwaysTemplate) // ?.withRenderingMode(.alwaysOriginal)
    }
    
    public var buttonIcon: UIImage? {
        
        var image: UIImage? = nil
        
        switch self {
        case .straighten:
            image = UIImage(systemName: "rectangle.slash")?.rotate(radians: -.pi/4, flipHorizontal: true)
        case .horizontalPerspective:
            image = UIImage(systemName: "perspective")?.rotate(radians: .pi)
        case .verticalPerspective:
            image = UIImage(systemName: "perspective")?.rotate(radians: -.pi/2)
        }
        return image?.withRenderingMode(.alwaysTemplate) // ?.withRenderingMode(.alwaysOriginal)
    }
}
