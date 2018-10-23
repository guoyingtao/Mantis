//
//  ViewController.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

// https://www.youtube.com/watch?v=AxN7HmKcKgE

class ViewController: UIViewController {
    var cropView: CropView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let image = UIImage(named: "sunflower.jpg") else {
            return
        }
        
        cropView = CropView(image: image)
        cropView.frame = view.frame
        cropView.delegate = self
        view.addSubview(cropView)
        
        cropView.translatesAutoresizingMaskIntoConstraints = false
        cropView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        cropView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        cropView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        cropView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        cropView.adaptForCropBox()
    }
    
}

extension ViewController: CropViewDelegate {
    func cropViewDidBecomeResettable(_ cropView: CropView) {
        
    }
    
    func cropViewDidBecomeNonResettable(_ cropView: CropView) {
        
    }
}
