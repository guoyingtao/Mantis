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
        
        let config = Mantis.Config()
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    @IBAction func presentWithPresetTransformation(_ sender: Any) {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        

        let transform = Transformation(offset: CGPoint(x: 231.66666666666666, y: 439.6666666666667),
                                       rotation: 0.5929909348487854,
                                                 scale: 2.841958076098717,
                                                 manualZoomed: true,
                                                 intialMaskFrame: CGRect(x: 14.0, y: 62.25, width: 347.0, height: 520.5),
                                                 maskFrame: CGRect(x: 59.47694524495677, y: 14.0, width: 256.04610951008647, height: 617.0),
                                                 scrollBounds: CGRect(x: 231.66666666666666, y: 439.6666666666667, width: 557.1387432741491, height: 654.7511809035641))
        
        
        config.presetTransformationType = .presetInfo(info: transform)
        
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    @IBAction func hideRotationDialPresent(_ sender: Any) {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        config.showRotationDial = false
        
        let cropViewController = Mantis.cropViewController(image: image, config: config)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }

    @IBAction func alwayUserOnPresetRatioPresent(_ sender: Any) {
            guard let image = image else {
                return
            }
            
            let config = Mantis.Config()
            
            let cropViewController = Mantis.cropViewController(image: image, config: config)
            cropViewController.modalPresentationStyle = .fullScreen
            cropViewController.delegate = self
            cropViewController.config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 16.0 / 9.0)
            present(cropViewController, animated: true)
        }
    
    
    @IBAction func customizedCropToolbarButtonTouched(_ sender: Any) {
        guard let image = image else {
            return
        }
        var config = Mantis.Config()
        
        config.cropToolbarConfig.cropToolbarHeightForVertialOrientation = 44
        config.cropToolbarConfig.cropToolbarWidthForHorizontalOrientation = 80
        
        let cropToolbar = CustomizedCropToolbar(frame: .zero)
        
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config,
                                                           cropToolbar: cropToolbar)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)

    }
    
    
    
    @IBAction func customizedCropToolbarWithoutListButtonTouched(_ sender: Any) {
        guard let image = image else {
            return
        }
        var config = Mantis.Config()
        
        config.cropToolbarConfig.cropToolbarHeightForVertialOrientation = 44
        config.cropToolbarConfig.cropToolbarWidthForHorizontalOrientation = 80
        
        let cropToolbar = CustomizedCropToolbarWithoutList(frame: .zero)
        
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config,
                                                           cropToolbar: cropToolbar)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
        
    }
    
    
    @IBAction func clockwiseRotationButtonTouched(_ sender: Any) {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        config.cropToolbarConfig.toolbarButtonOptions = [.clockwiseRotate, .reset, .ratio];
        
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    @IBAction func cropEllips(_ sender: Any) {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        config.cropShapeType = .ellipse()
        
        let cropViewController = Mantis.cropViewController(image: image, config: config)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }

    @IBAction func noBackgroundEffect(_ sender: Any) {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        config.cropVisualEffectType = .none
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
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
        
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation) {
        print(transformation);
        croppedImageView.image = cropped
        self.dismiss(animated: true)
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        self.dismiss(animated: true)
    }
}

extension ViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        guard let image = image else {
            return
        }
        
        self.image = image
        self.croppedImageView.image = image
    }
}
