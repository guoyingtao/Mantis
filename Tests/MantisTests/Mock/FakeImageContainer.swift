//
//  FakeImageContainer.swift
//  Mantis
//
//  Created by Yingtao Guo on 2/3/23.
//

import UIKit

class FakeImageContainer: UIView, ImageContainerProtocol {
    func contains(rect: CGRect, fromView view: UIView, tolerance: CGFloat) -> Bool {
        false
    }
    
    func getCropRegion(withCropBoxFrame cropBoxFrame: CGRect, cropView: UIView) -> CropRegion {
        CropRegion(topLeft: .zero, topRight: .zero, bottomLeft: .zero, bottomRight: .zero)
    }
}
