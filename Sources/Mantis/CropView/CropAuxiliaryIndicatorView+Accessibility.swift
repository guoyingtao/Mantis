//
//  CropAuxiliaryIndicatorView+Accessibility.swift
//  Mantis
//
//  Created by Yingtao Guo on 3/1/23.
//

import UIKit

let cropBoxHotAreaUnit: CGFloat = 42

extension CropAuxiliaryIndicatorView {
    func setupAccessibilityHelperViews () {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }

        accessibilityHelperViews.removeAll()
        for _ in 0..<8 {
            let helperView = UIView(frame: .zero)
            helperView.isAccessibilityElement = true
            addSubview(helperView)
            accessibilityHelperViews.append(helperView)
        }
    }
    
    func layoutAccessibilityHelperViews() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        
        for (index, helperView) in accessibilityHelperViews.enumerated() {
            guard let tappedEdge = CropViewAuxiliaryIndicatorHandleType(rawValue: index + 1) else {
                continue
            }
            
            switch tappedEdge {
            case .topLeft:
                helperView.frame = CGRect(x: -cropBoxHotAreaUnit/2, y: -cropBoxHotAreaUnit/2, width: cropBoxHotAreaUnit, height: cropBoxHotAreaUnit)
            case .top:
                helperView.frame = CGRect(x: cropBoxHotAreaUnit/2, y: -cropBoxHotAreaUnit/2, width: bounds.width - cropBoxHotAreaUnit, height: cropBoxHotAreaUnit)
            case .topRight:
                helperView.frame = CGRect(x: bounds.width - cropBoxHotAreaUnit/2, y: -cropBoxHotAreaUnit/2, width: cropBoxHotAreaUnit, height: cropBoxHotAreaUnit)
            case .right:
                helperView.frame = CGRect(x: bounds.width - cropBoxHotAreaUnit/2, y: cropBoxHotAreaUnit/2, width: cropBoxHotAreaUnit, height: bounds.height - cropBoxHotAreaUnit)
            case .bottomRight:
                helperView.frame = CGRect(x: bounds.width - cropBoxHotAreaUnit/2, y: bounds.height - cropBoxHotAreaUnit/2, width: cropBoxHotAreaUnit, height: cropBoxHotAreaUnit)
            case .bottom:
                helperView.frame = CGRect(x: cropBoxHotAreaUnit/2, y: bounds.height - cropBoxHotAreaUnit/2, width: bounds.width - cropBoxHotAreaUnit, height: cropBoxHotAreaUnit)
            case .bottomLeft:
                helperView.frame = CGRect(x: -cropBoxHotAreaUnit/2, y: bounds.height - cropBoxHotAreaUnit/2, width: cropBoxHotAreaUnit, height: cropBoxHotAreaUnit)
            case .left:
                helperView.frame = CGRect(x: -cropBoxHotAreaUnit/2, y: cropBoxHotAreaUnit/2, width: cropBoxHotAreaUnit, height: bounds.height - cropBoxHotAreaUnit)
            case .none:
                break
            }
        }
    }
}
