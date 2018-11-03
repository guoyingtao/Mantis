//
//  Mantis.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

public struct Mantis {
    
    static var config = Config()
    
    static public func buildCropViewController(image: UIImage) -> CropViewController {
        return CropViewController(image: image)
    }
    
    static public func buildCropView(image: UIImage) -> CropView {
        return CropView(image: image)
    }
}

