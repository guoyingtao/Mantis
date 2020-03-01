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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cancelButton.title = "Cancel"
        doneButton.title = "Done"
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func crop(_ sender: Any) {
        cropViewController?.crop()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CropViewController {
            vc.image = image
            vc.mode = .customizable
            vc.delegate = self
            
            var config = Mantis.Config()
            config.ratioOptions = [.original, .square, .custom]
            config.addCustomRatio(byVerticalWidth: 1, andVerticalHeight: 2)
            vc.config = config
            
            cropViewController = vc
        }
    }
}

extension EmbeddedCropViewController: CropViewControllerDelegate {
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation) {
        self.didGetCroppedImage?(cropped)
    }
    
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {}
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {}
}
