//
//  CropDimmingView.swift
//  Mantis
//
//  Created by Echo on 10/22/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

final class CropDimmingView: UIView, CropMaskProtocol {
    var overLayerFillColor = UIColor.black.cgColor    
    var maskLayer: CALayer?
    var cropShapeType: CropShapeType = .rect
    var imageRatio: CGFloat = 1.0
    
    convenience init(cropShapeType: CropShapeType = .rect) {
        self.init(frame: CGRect.zero)
        self.cropShapeType = cropShapeType
    }
    
    func setMask(cropRatio: CGFloat) {
        maskLayer?.removeFromSuperlayer()
        maskLayer = createMaskLayer(opacity: 0.5, cropRatio: cropRatio)
        layer.addSublayer(maskLayer!)
    }
}
