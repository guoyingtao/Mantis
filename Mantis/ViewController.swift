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
            
            let button1 = UIButton(type: .infoLight)
            vc.add(button: button1)
            button1.addTarget(self, action: #selector(tapButton1), for: .touchUpInside)
            
            let button2 = UIButton(type: .contactAdd)
            vc.add(button: button2)
            button2.addTarget(self, action: #selector(tapButton2), for: .touchUpInside)
            
            let button3 = UIButton(type: .infoDark)
            vc.add(button: button3)
            button3.addTarget(self, action: #selector(tapButton3), for: .touchUpInside)
        }
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
}
