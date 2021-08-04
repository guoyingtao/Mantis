//
//  CropVisualEffectView.swift
//  Mantis
//
//  Created by Echo on 10/22/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropVisualEffectView: UIVisualEffectView, CropMaskProtocol {
    var innerLayer: CALayer?
    
    var cropShapeType: CropShapeType = .rect
    var imageRatio: CGFloat = 1.0
    
    fileprivate var translucencyEffect: UIVisualEffect?
    
    convenience init(cropShapeType: CropShapeType = .rect,
                     effectType: CropVisualEffectType = .blurDark,
                     cropRatio: CGFloat = 1.0) {
        
        let (translucencyEffect, backgroundColor) = CropVisualEffectView.getEffect(byType: effectType)
        
        self.init(effect: translucencyEffect)
        self.cropShapeType = cropShapeType
        self.translucencyEffect = translucencyEffect
        self.backgroundColor = backgroundColor
        
        initialize(cropRatio: cropRatio)
    }
        
    func setMask(cropRatio: CGFloat) {
        let layer = createOverLayer(opacity: 0.98, cropRatio: cropRatio)
        
        let maskView = UIView(frame: self.bounds)
        maskView.clipsToBounds = true
        maskView.layer.addSublayer(layer)
        
        innerLayer = layer
        
        self.mask = maskView
    }
    
    static func getEffect(byType type: CropVisualEffectType) -> (UIVisualEffect?, UIColor) {
        switch type {
            case .blurDark: return (UIBlurEffect(style: .dark), .clear)
            case .dark: return (nil, UIColor.black.withAlphaComponent(0.75))
            case .light: return (nil, UIColor.black.withAlphaComponent(0.35))
            case .none: return (nil, .black)
        }
    }
    
}
