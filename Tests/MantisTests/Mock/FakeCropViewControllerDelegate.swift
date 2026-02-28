//
//  FakeCropViewControllerDelegate.swift
//  Mantis
//
//  Created by Yingtao Guo on 2/2/23.
//

import UIKit
@testable import Mantis

class FakeCropViewControllerDelegate: CropViewControllerDelegate {
    var didCrop = false
    var didFailedToCrop = false
    var didCancel = false
    var didBeginResize = false
    var didEndResize = false
    var didBeginCrop = false
    var didEndCrop = false
    var didImageTransformed = false
    
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
        didCrop = true
    }
    
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
        didFailedToCrop = true
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        didCancel = true
    }
    
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {
        didBeginResize = true
    }
    
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {
        didEndResize = true
    }
    
    func cropViewControllerDidBeginCrop(_ cropViewController: CropViewController) {
        didBeginCrop = true
    }
    
    func cropViewControllerDidEndCrop(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {
        didEndCrop = true
    }
    
    func cropViewControllerDidImageTransformed(_ cropViewController: CropViewController, transformation: Transformation) {
        didImageTransformed = true
    }
}
