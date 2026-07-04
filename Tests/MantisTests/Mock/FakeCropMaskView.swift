//
//  FakeCropMaskView.swift
//  MantisTests
//
//  Created by yingtguo on 2/5/23.
//

import UIKit
@testable import Mantis

class FakeCropMaskView: UIView, CropMaskProtocol {
    var maskLayer: CALayer?
    
    var overLayerFillColor: UIColor = .black
    
    var cropShapeType: Mantis.CropShapeType = .rect
    
    var innerLayer: CALayer?
    
    func setMask(cropRatio: CGFloat) {
        
    }
}
