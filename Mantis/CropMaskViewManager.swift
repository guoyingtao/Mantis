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

    init(with superview: UIView) {
        setup(in: superview)
    }
    
    private func setupOverlayView(in view: UIView) {
        dimmingView = CropDimmingView()
        dimmingView.isUserInteractionEnabled = false
        dimmingView.alpha = 0
        view.addSubview(dimmingView)
    }
    
    private func setupTranslucencyView(in view: UIView) {
        visualEffectView = CropVisualEffectView()
        visualEffectView.isUserInteractionEnabled = false
        view.addSubview(visualEffectView)
    }

    func setup(in view: UIView) {
        setupOverlayView(in: view)
        setupTranslucencyView(in: view)
    }
    
    func removeMaskViews() {
        dimmingView.removeFromSuperview()
        visualEffectView.removeFromSuperview()
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
    
    func adaptMaskTo(match cropRect: CGRect) {
        dimmingView.adaptMaskTo(match: cropRect)
        visualEffectView.adaptMaskTo(match: cropRect)
    }
}
