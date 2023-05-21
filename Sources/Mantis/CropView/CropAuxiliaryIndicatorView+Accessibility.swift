//
//  CropAuxiliaryIndicatorView+Accessibility.swift
//  Mantis
//
//  Created by Yingtao Guo on 3/1/23.
//

import UIKit

extension CropAuxiliaryIndicatorView {
    private func ifAccessibilityHelperNeeded() -> Bool {
        return UIAccessibility.isVoiceOverRunning
        || UIAccessibility.isSwitchControlRunning
        || UIAccessibility.isSpeakScreenEnabled
    }
    
    func setupAccessibilityHelperViews () {
        guard ifAccessibilityHelperNeeded() else {
            return
        }

        accessibilityHelperViews.removeAll()
        for index in 0..<8 {
            let helperView = UIView(frame: .zero)
            helperView.isAccessibilityElement = true
            
            addSubview(helperView)
            accessibilityHelperViews.append(helperView)
            
            guard let handleType = CropViewAuxiliaryIndicatorHandleType(rawValue: index + 1) else {
                continue
            }
            
            switch handleType {
            case .topLeft:
                helperView.accessibilityLabel = LocalizedHelper.getString("Mantis.Top left crop handle", value: "Top left crop handle")
            case .top:
                helperView.accessibilityLabel = LocalizedHelper.getString("Mantis.Top crop handle", value: "Top crop handle")
            case .topRight:
                helperView.accessibilityLabel = LocalizedHelper.getString("Mantis.Top right crop handle", value: "Top right crop handle")
            case .right:
                helperView.accessibilityLabel = LocalizedHelper.getString("Mantis.Right crop handle", value: "Right crop handle")
            case .bottomRight:
                helperView.accessibilityLabel = LocalizedHelper.getString("Mantis.Bottom right crop handle", value: "Bottom right crop handle")
            case .bottom:
                helperView.accessibilityLabel = LocalizedHelper.getString("Mantis.Bottom crop handle", value: "Bottom crop handle")
            case .bottomLeft:
                helperView.accessibilityLabel = LocalizedHelper.getString("Mantis.Bottom left crop handle", value: "Bottom left crop handle")
            case .left:
                helperView.accessibilityLabel = LocalizedHelper.getString("Mantis.Left crop handle", value: "Left crop handle")
            case .none:
                break
            }
            
            helperView.accessibilityHint = LocalizedHelper.getString("Mantis.Double tap and hold to adjust crop area",
                                                                     value: "Double tap and hold to adjust crop area")
        }
    }
    
    func layoutAccessibilityHelperViews() {
        guard ifAccessibilityHelperNeeded() else {
            return
        }
        
        for (index, helperView) in accessibilityHelperViews.enumerated() {
            guard let handleType = CropViewAuxiliaryIndicatorHandleType(rawValue: index + 1) else {
                continue
            }
            
            switch handleType {
            case .topLeft:
                helperView.frame = CGRect(x: -cropBoxHotAreaUnit/2,
                                          y: -cropBoxHotAreaUnit/2,
                                          width: cropBoxHotAreaUnit,
                                          height: cropBoxHotAreaUnit)
            case .top:
                helperView.frame = CGRect(x: cropBoxHotAreaUnit/2,
                                          y: -cropBoxHotAreaUnit/2,
                                          width: bounds.width - cropBoxHotAreaUnit,
                                          height: cropBoxHotAreaUnit)
            case .topRight:
                helperView.frame = CGRect(x: bounds.width - cropBoxHotAreaUnit/2,
                                          y: -cropBoxHotAreaUnit/2,
                                          width: cropBoxHotAreaUnit,
                                          height: cropBoxHotAreaUnit)
            case .right:
                helperView.frame = CGRect(x: bounds.width - cropBoxHotAreaUnit/2,
                                          y: cropBoxHotAreaUnit/2,
                                          width: cropBoxHotAreaUnit,
                                          height: bounds.height - cropBoxHotAreaUnit)
            case .bottomRight:
                helperView.frame = CGRect(x: bounds.width - cropBoxHotAreaUnit/2,
                                          y: bounds.height - cropBoxHotAreaUnit/2,
                                          width: cropBoxHotAreaUnit,
                                          height: cropBoxHotAreaUnit)
            case .bottom:
                helperView.frame = CGRect(x: cropBoxHotAreaUnit/2,
                                          y: bounds.height - cropBoxHotAreaUnit/2,
                                          width: bounds.width - cropBoxHotAreaUnit,
                                          height: cropBoxHotAreaUnit)
            case .bottomLeft:
                helperView.frame = CGRect(x: -cropBoxHotAreaUnit/2,
                                          y: bounds.height - cropBoxHotAreaUnit/2,
                                          width: cropBoxHotAreaUnit,
                                          height: cropBoxHotAreaUnit)
            case .left:
                helperView.frame = CGRect(x: -cropBoxHotAreaUnit/2,
                                          y: cropBoxHotAreaUnit/2,
                                          width: cropBoxHotAreaUnit,
                                          height: bounds.height - cropBoxHotAreaUnit)
            case .none:
                break
            }
        }
    }
}
