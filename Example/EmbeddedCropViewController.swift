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
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var cancelText = "Cancel"
        if let bundle = Mantis.bundle {
            cancelText = NSLocalizedString("Cancel", tableName: "MantisLocalizable", bundle: bundle, value: "Cancel", comment: "")
        }
        
        cancelButton.title = cancelText
        
        var doneText = "Done"
        if let bundle = Mantis.bundle {
            doneText = NSLocalizedString("Done", tableName: "MantisLocalizable", bundle: bundle, value: "Done", comment: "")
        }
        
        doneButton.title = doneText
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
            config.addCustomRatio(byWidth: 2, andHeight: 1)
            vc.config = config
            
            cropViewController = vc
        }
    }
}

extension EmbeddedCropViewController: CropViewControllerProtocal {
    func didGetCroppedImage(image: UIImage) {
        print("get the cropped image.")
    }
}
