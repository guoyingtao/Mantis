//
//  Mantis.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

public struct Mantis {
    
    public var config = Config.shared
    
    public func cropViewController(image: UIImage) -> CropViewController {
        return CropViewController(image: image, mode: .normal)
    }
}

