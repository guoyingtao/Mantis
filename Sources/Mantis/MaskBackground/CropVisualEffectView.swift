//
//  CropVisualEffectView.swift
//  Mantis
//
//  Created by Echo on 10/22/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropMaskVisualEffectView: UIVisualEffectView, CropMaskProtocol {
    var innerLayer: CALayer?
    
    var cropShapeType: CropShapeType = .rect
    var imageRatio: CGFloat = 1.0
    
    private var translucencyEffect: UIVisualEffect?
    
    convenience init(cropShapeType: CropShapeType = .rect,
                     effectType: CropMaskVisualEffectType = .blurDark) {
        
        let (translucencyEffect, backgroundColor) = CropMaskVisualEffectView.getEffect(byType: effectType)
        
        self.init(effect: translucencyEffect)
        self.cropShapeType = cropShapeType
        self.translucencyEffect = translucencyEffect
        self.backgroundColor = backgroundColor
    }
        
    func setMask(cropRatio: CGFloat) {
        let layer = createOverLayer(opacity: 0.98, cropRatio: cropRatio)
        
        let maskView = UIView(frame: self.bounds)
        maskView.clipsToBounds = true
        maskView.layer.addSublayer(layer)
        
        innerLayer = layer
        
        self.mask = maskView
    }
    
    static func getEffect(byType type: CropMaskVisualEffectType) -> (UIVisualEffect?, UIColor) {
        switch type {
        case .blurDark:
            return (UIBlurEffect(style: .dark), .clear)
        case .dark:
            return (nil, UIColor.black.withAlphaComponent(0.75))
        case .light:
            return (nil, UIColor.black.withAlphaComponent(0.35))
        case .none:
            return (nil, .black)
        }
    }
    
}
