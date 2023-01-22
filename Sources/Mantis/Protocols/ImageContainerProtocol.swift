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
}
