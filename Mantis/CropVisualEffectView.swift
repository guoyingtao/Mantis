//
//  CropVisualEffectView.swift
//  Mantis
//
//  Created by Echo on 10/22/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropVisualEffectView: UIVisualEffectView {
    
    fileprivate var translucencyEffect: UIVisualEffect?
    
    convenience init() {
        let translucencyEffect = UIBlurEffect(style: .dark)
        self.init(effect: translucencyEffect)
        self.translucencyEffect = translucencyEffect
        initialize()
    }
        
    func toggle(visible: Bool) {
        
    }
}

extension CropVisualEffectView: CropMaskProtocal {
    func setMask() {
        let layer = createOverLayer(opacity: 0.98)
        
        let maskView = UIView(frame: self.bounds)
        maskView.clipsToBounds = true
        maskView.layer.addSublayer(layer)
        
        self.mask = maskView
    }
}
