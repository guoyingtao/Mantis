//
//  CropVisualEffectView.swift
//  Mantis
//
//  Created by Echo on 10/22/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

final class CropMaskVisualEffectView: UIVisualEffectView, CropMaskProtocol {
    var overLayerFillColor: UIColor = .black
    var maskLayer: CALayer?
    var cropShapeType: CropShapeType = .rect
    var imageRatio: CGFloat = 1.0
    
    private var translucencyEffect: UIVisualEffect?
    private var effectType: CropMaskVisualEffectType = .blurDark
    
    convenience init(cropShapeType: CropShapeType = .rect,
                     effectType: CropMaskVisualEffectType = .blurDark) {
        
        let (translucencyEffect, backgroundColor) = CropMaskVisualEffectView.getEffect(byType: effectType)
        
        self.init(effect: translucencyEffect)
        self.cropShapeType = cropShapeType
        self.effectType = effectType
        self.translucencyEffect = translucencyEffect
        self.backgroundColor = backgroundColor
    }
        
    func setMask(cropRatio: CGFloat) {
        maskLayer?.removeFromSuperlayer()        
        maskLayer = createMaskLayer(opacity: 0.98, cropRatio: cropRatio)
        
        let maskView = UIView(frame: self.bounds)
        maskView.clipsToBounds = true
        maskView.layer.addSublayer(maskLayer!)
        
        self.mask = maskView
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if case .blurSystem = effectType {
            if #available(iOS 13.0, *),
               traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                applyBlurSystemEffect()
            }
        }
    }
    
    private func applyBlurSystemEffect() {
        if #available(iOS 13.0, *) {
            let isDark = traitCollection.userInterfaceStyle == .dark
            if isDark {
                self.effect = UIBlurEffect(style: .dark)
                self.backgroundColor = .clear
            } else {
                self.effect = UIBlurEffect(style: .extraLight)
                self.backgroundColor = .clear
            }
        }
    }
    
    static func getEffect(byType type: CropMaskVisualEffectType) -> (UIVisualEffect?, UIColor) {
        switch type {
        case .blurDark:
            return (UIBlurEffect(style: .dark), .clear)
        case .dark:
            return (nil, UIColor.black.withAlphaComponent(0.75))
        case .light:
            return (nil, UIColor.black.withAlphaComponent(0.35))
        case .custom(let color):
            return(nil, color)
        case .blurSystem:
            // Initial value; will be corrected by applyBlurSystemEffect() once
            // the view is in the hierarchy and traitCollection is available.
            return (UIBlurEffect(style: .dark), .clear)
        case .default:
            return (nil, .black)
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if case .blurSystem = effectType, window != nil {
            applyBlurSystemEffect()
        }
    }
}
