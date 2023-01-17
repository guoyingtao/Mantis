//
//  ImageContainerProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import UIKit

protocol ImageContainerProtocol: UIView {
    init(with image: UIImage)
    func contains(rect: CGRect, fromView view: UIView, tolerance: CGFloat) -> Bool
}
