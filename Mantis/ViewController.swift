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
    
    
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var rotateButton: UIButton!
    @IBOutlet weak var cropButton: UIButton!
    
    @IBOutlet weak var croppedImageView: UIImageView!
    
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
        cropView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100).isActive = true
        cropView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        cropView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        self.view.backgroundColor = .black
    }
    
    override func viewDidLayoutSubviews() {
        cropView.adaptForCropBox()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        view.bringSubviewToFront(cropButton)
        view.bringSubviewToFront(resetButton)
        view.bringSubviewToFront(rotateButton)
        view.bringSubviewToFront(croppedImageView)
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
        
        croppedImageView.image = image
    }
    
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            
            let translation = gestureRecognizer.translation(in: self.view)
            // note: 'view' is optional and need to be unwrapped
            gestureRecognizer.view!.center = CGPoint(x: gestureRecognizer.view!.center.x + translation.x, y: gestureRecognizer.view!.center.y + translation.y)
            gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
        }
    }
}

extension ViewController: CropViewDelegate {
    func cropViewDidBecomeResettable(_ cropView: CropView) {
        
    }
    
    func cropViewDidBecomeNonResettable(_ cropView: CropView) {
        
    }
}
