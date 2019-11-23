//
//  ViewController.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit
import Mantis

class ViewController: UIViewController, CropViewControllerDelegate {
    var image = UIImage(named: "sunflower.jpg")
    
    @IBOutlet weak var croppedImageView: UIImageView!
    var imagePicker: ImagePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        
//        if let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as? UIView {
//            statusBar.backgroundColor = .black
//        }        
        
//        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
        
    @IBAction func getImageFromAlbum(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    @IBAction func normalPresent(_ sender: Any) {
        guard let image = image else {
            return
        }
        
//        Mantis.Config.integratedByCocoaPods = false
        let config = Mantis.Config()
//        config.ratioOptions = [.square]
//        config.alwaysUsingOnePresetFixedRatio = true
        
        let cropViewController = Mantis.cropViewController(image: image, config: config)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nc = segue.destination as? UINavigationController,
            let vc = nc.viewControllers.first as? EmbeddedCropViewController {
            vc.image = image
            vc.didGetCroppedImage = {[weak self] image in
                self?.croppedImageView.image = image
                self?.dismiss(animated: true)
            }
        }
    }
    
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage) {
        croppedImageView.image = cropped
    }    
}

extension ViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        self.image = image
        self.croppedImageView.image = image
    }
}
