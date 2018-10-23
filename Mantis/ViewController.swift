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

  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let image = UIImage(named: "sunflower.jpg") else {
        return
    }
    
    let cropView = CropView(image: image)
    cropView.frame = view.frame
    cropView.delegate = self
    cropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(cropView)
    
    cropView.moveCroppedContentToCenter()
    cropView.performInitialSetup()
    
//    cropView.translatesAutoresizingMaskIntoConstraints = false
//    cropView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//    cropView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//    cropView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//    cropView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
  }

}

extension ViewController: CropViewDelegate {
    func cropViewDidBecomeResettable(_ cropView: CropView) {
        
    }
    
    func cropViewDidBecomeNonResettable(_ cropView: CropView) {
        
    }
}
