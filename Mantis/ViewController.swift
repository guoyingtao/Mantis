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
    
    func didGetCroppedImage(image: UIImage) {
        croppedImageView.image = image
    }
    
    @IBOutlet weak var croppedImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        croppedImageView.image = image
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Normal", let nc = segue.destination as? UINavigationController, let vc = nc.viewControllers.first as? CropViewController {
            vc.delegate = self
            vc.image = image
        } else if segue.identifier == "Custom", let nc = segue.destination as? UINavigationController, let vc = nc.viewControllers.first as? CropViewController {
            vc.delegate = self
            vc.image = image
            vc.mode = .embedded
        }
    }
}
