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
        // iOS 17+ uses the modern trait-change registration; earlier versions
        // (the library supports iOS 15) fall back to `traitCollectionDidChange`.
        if #available(iOS 17.0, *) {
            registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) { (self: Self, previous: UITraitCollection) in
                if case .blurSystem = self.effectType,
                   self.traitCollection.hasDifferentColorAppearance(comparedTo: previous) {
                    self.applyBlurSystemEffect()
                }
            }
        }
    }

    // iOS 16 and earlier: `registerForTraitChanges` is unavailable, so use the
    // (pre-iOS-17) trait-change hook. On iOS 17+ the registration above handles it.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #unavailable(iOS 17.0) else { return }
        if case .blurSystem = effectType,
           let previousTraitCollection,
           traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyBlurSystemEffect()
        }
    }
        
    func setMask(cropRatio: CGFloat) {
        maskLayer?.removeFromSuperlayer()        
        maskLayer = createMaskLayer(opacity: 0.98, cropRatio: cropRatio)
        
        let maskView = UIView(frame: self.bounds)
        maskView.clipsToBounds = true
        maskView.layer.addSublayer(maskLayer!)
        
        self.mask = maskView
    }
    
    private func applyBlurSystemEffect() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        if isDark {
            self.effect = UIBlurEffect(style: .dark)
            self.backgroundColor = .clear
        } else {
            // Blur effects sample underlying content, so they can appear
            // dark over colorful images. Use a solid light background
            // instead to guarantee a light appearance in light mode.
            self.effect = nil
            self.backgroundColor = UIColor(white: 0.95, alpha: 0.98)
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
