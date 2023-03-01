//
//  CropAuxiliaryIndicatorView+Accessibility.swift
//  Mantis
//
//  Created by Yingtao Guo on 3/1/23.
//

import UIKit

extension CropAuxiliaryIndicatorView {
    func setupAccessibilityHelperViews () {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }

        accessibilityHelperViews.removeAll()
        for i in 0..<8 {
            let helperView = UIView(frame: .zero)
            helperView.isAccessibilityElement = true
            
            addSubview(helperView)
            accessibilityHelperViews.append(helperView)
            
            guard let handleType = CropViewAuxiliaryIndicatorHandleType(rawValue: i + 1) else {
                continue
            }
            
            switch handleType {
            case .topLeft:
                helperView.accessibilityLabel = "Top left crop handle"
            case .top:
                helperView.accessibilityLabel = "Top crop handle"
            case .topRight:
                helperView.accessibilityLabel = "Top right crop handle"
            case .right:
                helperView.accessibilityLabel = "Right crop handle"
            case .bottomRight:
                helperView.accessibilityLabel = "Bottom right crop handle"
            case .bottom:
                helperView.accessibilityLabel = "Bottom crop handle"
            case .bottomLeft:
                helperView.accessibilityLabel = "Bottom left crop handle"
            case .left:
                helperView.accessibilityLabel = "Left crop handle"
            case .none:
                break
            }
            
            helperView.accessibilityHint = "Double tap and hold to adjust crop area"
        }
    }
    
    func layoutAccessibilityHelperViews() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        
        for (index, helperView) in accessibilityHelperViews.enumerated() {
            guard let handleType = CropViewAuxiliaryIndicatorHandleType(rawValue: index + 1) else {
                continue
            }
            
            switch handleType {
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
