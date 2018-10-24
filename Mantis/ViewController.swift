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
        cropView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100).isActive = true
        cropView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        cropView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        self.view.backgroundColor = .black
        
//        let dashBoard = AngleDashboard(frame: CGRect(x: 60, y: 100, width: 300, height: 100))
//        view.addSubview(dashBoard)
//
//        UIView.animate(withDuration: 4) {
//            dashBoard.rotateDailPlate(by: -CGFloat.pi / 2)
//        }
    }
    
    override func viewDidLayoutSubviews() {
        cropView.adaptForCropBox()
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
