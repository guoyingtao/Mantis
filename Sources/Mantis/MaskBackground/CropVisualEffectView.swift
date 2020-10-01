//
//  CropVisualEffectView.swift
//  Mantis
//
//  Created by Echo on 10/22/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropVisualEffectView: UIVisualEffectView, CropMaskProtocol {
    var cropShapeType: CropShapeType = .rect
    
    fileprivate var translucencyEffect: UIVisualEffect?
    
    convenience init(cropShapeType: CropShapeType = .rect, effectType: CropVisualEffectType = .blurDark) {
        
        let translucencyEffect = CropVisualEffectView.getEffect(byType: effectType)
        
        self.init(effect: translucencyEffect)
        self.cropShapeType = cropShapeType
        self.translucencyEffect = translucencyEffect
        self.backgroundColor = effectType == .none ? .black : .clear
        
        initialize()
    }
        
    func setMask() {
        let layer = createOverLayer(opacity: 0.98)
        
        let maskView = UIView(frame: self.bounds)
        maskView.clipsToBounds = true
        maskView.layer.addSublayer(layer)
        
        self.mask = maskView
    }
    
    static func getEffect(byType type: CropVisualEffectType) -> UIVisualEffect? {
        switch type {
        case .blurDark: return UIBlurEffect(style: .dark)
        case .none: return nil
        }
    }
}
