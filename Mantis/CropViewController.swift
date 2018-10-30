//
//  CropViewController.swift
//  Mantis
//
//  Created by Echo on 10/30/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

protocol CropViewControllerProtocal {
    func didGetCroppedImage(image: UIImage)
}

class CropViewController: UIViewController {
    
    var delegate: CropViewControllerProtocal?
    
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var rotateButton: UIButton!
    @IBOutlet weak var cropButton: UIButton!
    
    var cropView: CropView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let image = UIImage(named: "sunflower.jpg") else {
            return
        }
        
        cropView = CropView(image: image)
        cropView.frame = view.frame
        cropView.delegate = self
        cropView.clipsToBounds = true
        view.addSubview(cropView)
        
        cropView.translatesAutoresizingMaskIntoConstraints = false
        cropView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        cropView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60).isActive = true
        cropView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        cropView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

    }
    
    override func viewDidLayoutSubviews() {
        cropView.adaptForCropBox()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        view.bringSubviewToFront(cropButton)
        view.bringSubviewToFront(resetButton)
        view.bringSubviewToFront(rotateButton)
    }

    @IBAction func reset(_ sender: Any) {
        cropView.reset()
    }
    
    @IBAction func rotate(_ sender: Any) {
        cropView.clockwiseRotate90()
    }
    
    @IBAction func crop(_ sender: Any) {
        guard let image = cropView.crop() else {
            return
        }
        
        dismiss(animated: true) {
            self.delegate?.didGetCroppedImage(image: image)
        }
    }

}

extension CropViewController: CropViewDelegate {
    func cropViewDidBecomeResettable(_ cropView: CropView) {
        
    }
    
    func cropViewDidBecomeNonResettable(_ cropView: CropView) {
        
    }
}
