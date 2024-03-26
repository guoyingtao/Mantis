//
//  ImageContainerProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import UIKit

protocol ImageContainerProtocol: UIView {
    func contains(rect: CGRect, fromView view: UIView, tolerance: CGFloat) -> Bool
    func getCropRegion(withCropBoxFrame cropBoxFrame: CGRect, cropView: UIView) -> CropRegion
    func update(_ image: UIImage)
}

extension ImageContainerProtocol {
    func update(_ image: UIImage) {}
}
