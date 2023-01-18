//
//  CropMaskViewManagerProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import UIKit

protocol CropMaskViewManagerProtocol {
    var cropShapeType: CropShapeType { get set }
    var cropMaskVisualEffectType: CropMaskVisualEffectType { get set }

    func setup(in view: UIView, cropRatio: CGFloat)
    func removeMaskViews()
    func bringMaskViewsToFront()
    func showDimmingBackground()
    func showVisualEffectBackground()
    func adaptMaskTo(match cropRect: CGRect, cropRatio: CGFloat)
}
