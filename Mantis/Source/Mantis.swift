//
//  Mantis.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

public struct Mantis {
    
    static var config = Config.shared
    
    static public func cropViewController(image: UIImage) -> CropViewController {
        return CropViewController(image: image, mode: .normal)
    }
    
    // TO DO
    static private func customizableCropViewController(image: UIImage) -> CropViewController {
        return CropViewController(image: image, mode: .customizable)
    }
}

