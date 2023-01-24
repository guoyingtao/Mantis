//
//  CropMaskViewManagerProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import UIKit

protocol CropMaskViewManagerProtocol {
    func setup(in view: UIView, cropRatio: CGFloat)
    func removeMaskViews()
    func showDimmingBackground(animated: Bool)
    func showVisualEffectBackground(animated: Bool)
    func adaptMaskTo(match cropRect: CGRect, cropRatio: CGFloat)
}
