//
//  CropMaskViewManager.swift
//  Mantis
//
//  Created by Echo on 10/28/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

final class CropMaskViewManager {
    private var dimmingView: CropDimmingView?
    private var visualEffectView: CropMaskVisualEffectView?
    
    var cropShapeType: CropShapeType = .rect
    var cropMaskVisualEffectType: CropMaskVisualEffectType = .blurDark
    
    init(cropShapeType: CropShapeType = .rect,
         cropMaskVisualEffectType: CropMaskVisualEffectType = .blurDark) {
        
        self.cropShapeType = cropShapeType
        self.cropMaskVisualEffectType = cropMaskVisualEffectType
    }

    private func setupOverlayView(in view: UIView, cropRatio: CGFloat = 1.0) {
        dimmingView = CropDimmingView(cropShapeType: cropShapeType, cropRatio: cropRatio)
        dimmingView?.isUserInteractionEnabled = false
        dimmingView?.alpha = 0
        view.addSubview(dimmingView!)
    }
    
    private func setupTranslucencyView(in view: UIView, cropRatio: CGFloat = 1.0) {
        visualEffectView = CropMaskVisualEffectView(cropShapeType: cropShapeType,
                                                    effectType: cropMaskVisualEffectType,
                                                    cropRatio: cropRatio)
        visualEffectView?.isUserInteractionEnabled = false
        view.addSubview(visualEffectView!)
    }
}

extension CropMaskViewManager: CropMaskViewManagerProtocol {
    func setup(in view: UIView, cropRatio: CGFloat = 1.0) {
        setupOverlayView(in: view, cropRatio: cropRatio)
        setupTranslucencyView(in: view, cropRatio: cropRatio)
    }
    
    func removeMaskViews() {
        dimmingView?.removeFromSuperview()
        visualEffectView?.removeFromSuperview()
    }
    
    func bringMaskViewsToFront() {
        if let dimmingView = dimmingView {
            dimmingView.superview?.bringSubviewToFront(dimmingView)
        }
        
        if let visualEffectView = visualEffectView {
            visualEffectView.superview?.bringSubviewToFront(visualEffectView)
        }
    }
    
    func showDimmingBackground() {
        UIView.animate(withDuration: 0.1) {
            self.dimmingView?.alpha = 1
            self.visualEffectView?.alpha = 0
        }
    }
    
    func showVisualEffectBackground() {
        UIView.animate(withDuration: 0.5) {
            self.dimmingView?.alpha = 0
            self.visualEffectView?.alpha = 1
        }
    }
    
    func adaptMaskTo(match cropRect: CGRect, cropRatio: CGFloat) {
        dimmingView?.adaptMaskTo(match: cropRect, cropRatio: cropRatio)
        visualEffectView?.adaptMaskTo(match: cropRect, cropRatio: cropRatio)
    }
}
