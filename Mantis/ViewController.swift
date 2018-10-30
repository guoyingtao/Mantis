//
//  ViewController.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

// https://www.youtube.com/watch?v=AxN7HmKcKgE

class ViewController: UIViewController, CropViewControllerProtocal {
    func didGetCroppedImage(image: UIImage) {
        croppedImageView.image = image
    }
    
    @IBOutlet weak var croppedImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CropViewController {
            vc.delegate = self
        }
    }
}
