//
//  CropMaskViewManager.swift
//  Mantis
//
//  Created by Echo on 10/28/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropMaskViewManager {
    fileprivate var dimmingView: CropDimmingView!
    fileprivate var visualEffectView: CropVisualEffectView!
    
    var cropShapeType: CropShapeType = .rect
    var cropVisualEffectType: CropVisualEffectType = .blurDark
    
    init(with superview: UIView,
         cropRatio: CGFloat = 1.0,
         cropShapeType: CropShapeType = .rect,
         cropVisualEffectType: CropVisualEffectType = .blurDark) {
        
        setup(in: superview, cropRatio: cropRatio)
        self.cropShapeType = cropShapeType
        self.cropVisualEffectType = cropVisualEffectType
    }
    
    private func setupOverlayView(in view: UIView, cropRatio: CGFloat = 1.0) {
        dimmingView = CropDimmingView(cropShapeType: cropShapeType, cropRatio: cropRatio)
        dimmingView.isUserInteractionEnabled = false
        dimmingView.alpha = 0
        view.addSubview(dimmingView)
    }
    
    private func setupTranslucencyView(in view: UIView, cropRatio: CGFloat = 1.0) {
        visualEffectView = CropVisualEffectView(cropShapeType: cropShapeType,
                                                effectType: cropVisualEffectType,
                                                cropRatio: cropRatio)
        visualEffectView.isUserInteractionEnabled = false
        view.addSubview(visualEffectView)
    }

    func setup(in view: UIView, cropRatio: CGFloat = 1.0) {
        setupOverlayView(in: view, cropRatio: cropRatio)
        setupTranslucencyView(in: view, cropRatio: cropRatio)
    }
    
    func removeMaskViews() {
        dimmingView.removeFromSuperview()
        visualEffectView.removeFromSuperview()
    }
    
    func bringMaskViewsToFront() {
        dimmingView.superview?.bringSubviewToFront(dimmingView)
        visualEffectView.superview?.bringSubviewToFront(visualEffectView)
    }
    
    func showDimmingBackground() {
        UIView.animate(withDuration: 0.1) {
            self.dimmingView.alpha = 1
            self.visualEffectView.alpha = 0
        }
    }
    
    func showVisualEffectBackground() {
        UIView.animate(withDuration: 0.5) {
            self.dimmingView.alpha = 0
            self.visualEffectView.alpha = 1
        }
    }
    
    func adaptMaskTo(match cropRect: CGRect, cropRatio: CGFloat) {
        dimmingView.adaptMaskTo(match: cropRect, cropRatio: cropRatio)
        visualEffectView.adaptMaskTo(match: cropRect, cropRatio: cropRatio)
    }
}
