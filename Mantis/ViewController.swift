//
//  ViewController.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CropViewControllerProtocal {
    func didGetCroppedImage(image: UIImage) {
        croppedImageView.image = image
    }
    
    @IBOutlet weak var croppedImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        croppedImageView.image = UIImage(named: "sunflower1.jpg")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nc = segue.destination as? UINavigationController, let vc = nc.viewControllers.first as? CropViewController {
            vc.delegate = self
            vc.image = croppedImageView.image
        }
    }
}
