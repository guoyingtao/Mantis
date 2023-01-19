//
//  CropDimmingView.swift
//  Mantis
//
//  Created by Echo on 10/22/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropDimmingView: UIView, CropMaskProtocol {
    var innerLayer: CALayer?
    
    var cropShapeType: CropShapeType = .rect
    var imageRatio: CGFloat = 1.0
    
    convenience init(cropShapeType: CropShapeType = .rect) {
        self.init(frame: CGRect.zero)
        self.cropShapeType = cropShapeType
    }
    
    func setMask(cropRatio: CGFloat) {
        let layer = createOverLayer(opacity: 0.5, cropRatio: cropRatio)
        self.layer.addSublayer(layer)
        innerLayer = layer
    }
}
