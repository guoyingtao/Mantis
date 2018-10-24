//
//  CropDimmingView.swift
//  Mantis
//
//  Created by Echo on 10/22/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropDimmingView: UIView {
    convenience init() {
        self.init(frame: CGRect.zero)
        initialize()
    }
}

extension CropDimmingView: CropMaskProtocal {
    func setMask() {
        let layer = createOverLayer(opacity: 0.5)
        self.layer.addSublayer(layer)
    }
}
