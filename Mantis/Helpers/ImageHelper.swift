//
//  ImageHelper.swift
//  Mantis
//
//  Created by Echo on 10/26/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

struct ImageHelper {
    static func cropImage(image: UIImage, cropRect: CGRect, rotation: CGFloat = 0) -> UIImage
    {
        print("crop rect is \(cropRect)")
        UIGraphicsBeginImageContextWithOptions(cropRect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        context?.translateBy(x: 0.0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.rotate(by: rotation)
        context?.draw(image.cgImage!, in: CGRect(x: -cropRect.origin.x, y:cropRect.origin.y, width:image.size.width, height:image.size.height), byTiling: false)
        context?.clip(to: [cropRect])
        
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return croppedImage!
    }
}
