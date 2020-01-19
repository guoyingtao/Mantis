//
//  CropDimmingView.swift
//  Mantis
//
//  Created by Echo on 10/22/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropDimmingView: UIView, CropMaskProtocol {
    var cropShapeType: CropShapeType = .rect
    
    convenience init(cropShapeType: CropShapeType = .rect) {
        self.init(frame: CGRect.zero)
        self.cropShapeType = cropShapeType
        initialize()
    }
    
    func setMask() {
        let layer = createOverLayer(opacity: 0.5)
        self.layer.addSublayer(layer)
    }
}
