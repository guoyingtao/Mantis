//
//  Mantis.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

public struct Mantis {
    
    static public func cropViewController(image: UIImage, config: MantisConfig = MantisConfig()) -> CropViewController {
        return CropViewController(image: image, config: config, mode: .normal)
    }
    
    static public func cropCustomizableViewController(image: UIImage, config: MantisConfig = MantisConfig()) -> CropViewController {
        return CropViewController(image: image, config: config, mode: .customizable)
    }
}

