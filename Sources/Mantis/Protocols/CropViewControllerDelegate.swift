//
//  CropViewControllerDelegate.swift
//  Mantis
//
//  Created by yingtguo on 1/20/23.
//

import UIKit

public protocol CropViewControllerDelegate: AnyObject {
    func cropViewControllerDidCrop(_ cropViewController: CropViewController,
                                   cropped: UIImage,
                                   transformation: Transformation,
                                   cropInfo: CropInfo)
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage)
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage)
    
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController)
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo)
    func cropViewControllerDidImageTransformed(_ cropViewController: CropViewController)
    func cropViewController(_ cropViewController: CropViewController, didBecomeResettable resettable: Bool)
}

public extension CropViewControllerDelegate {
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {}
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {}
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {}
    func cropViewControllerDidImageTransformed(_ cropViewController: CropViewController) {}
    func cropViewController(_ cropViewController: CropViewController, didBecomeResettable resettable: Bool) {}
}
