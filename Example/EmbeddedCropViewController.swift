//
//  EmbeddedCropViewController.swift
//  MantisExample
//
//  Created by Echo on 11/9/18.
//  Copyright © 2018 Echo. All rights reserved.
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cancelButton.title = "Cancel"
        doneButton.title = "Done"
        resolutionLabel.text = "\(getResolution(image: image) ?? "unknown")"
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func crop(_ sender: Any) {
        cropViewController?.crop()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cropViewController = segue.destination as? CropViewController {
            cropViewController.image = image
            cropViewController.mode = .customizable
            cropViewController.delegate = self
            
            let config = Mantis.Config()
            cropViewController.config = config
            
            self.cropViewController = cropViewController
        }
    }
    
    private func getResolution(image: UIImage?) -> String? {
        if let size = image?.size {
            return "\(Int(size.width)) x \(Int(size.height)) pixels"
        }
        return nil
    }
}

extension EmbeddedCropViewController: CropViewControllerDelegate {
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
