//
//  ViewController.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CropViewControllerProtocal {
    let image = UIImage(named: "sunflower.jpg")
    
    @IBOutlet weak var croppedImageView: UIImageView!
    
    @IBAction func normalPresent(_ sender: Any) {
        guard let image = image else {
            return
        }
        let cropViewController = Mantis.cropViewController(image: image)
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nc = segue.destination as? UINavigationController, let vc = nc.viewControllers.first as? EmbeddedCropViewController {
            vc.image = image
        }
    }
    
    func didGetCroppedImage(image: UIImage) {
        croppedImageView.image = image
    }
}
