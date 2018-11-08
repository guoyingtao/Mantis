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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        croppedImageView.image = image
    }
    
    @objc func tapButton1() {
        print("tap button1")
    }
    
    @objc func tapButton2() {
        print("tap button2")
    }
    
    @objc func tapButton3() {
        print("tap button3")
    }
    
    @IBAction func normalPresent(_ sender: Any) {
        guard let image = image else {
            return
        }
        let cropViewController = Mantis.cropViewController(image: image)
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    @IBAction func customizablePresent(_ sender: Any) {
        guard let image = image else {
            return
        }
        
        Mantis.config.addCustomRatio(ratioItem: (nameH: "2:1", ratioH: 2.0,nameV: "1:2", ratioV: 0.5))
        let cropViewController = Mantis.customizableCropViewController(image: image)
        cropViewController.delegate = self
        
        let button1 = UIButton(type: .infoLight)
        cropViewController.add(button: button1)
        button1.addTarget(self, action: #selector(tapButton1), for: .touchUpInside)
        
        let button2 = UIButton(type: .contactAdd)
        cropViewController.add(button: button2)
        button2.addTarget(self, action: #selector(tapButton2), for: .touchUpInside)
        
        let button3 = UIButton(type: .infoDark)
        cropViewController.add(button: button3)
        button3.addTarget(self, action: #selector(tapButton3), for: .touchUpInside)
        
        present(cropViewController, animated: true)
    }
    
    func didGetCroppedImage(image: UIImage) {
        croppedImageView.image = image
    }
}
