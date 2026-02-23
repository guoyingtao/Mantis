//
//  CropView+Flip.swift
//  Mantis
//
//  Extracted from CropView.swift
//

import UIKit

// MARK: - Flip
extension CropView {
    func flipCropWorkbenchViewIfNeeded() {
        if viewModel.horizontallyFlip {
            let scale: CGFloat = viewModel.rotationType.isRotatedByMultiple180 ? -1 : 1
            cropWorkbenchView.transformScaleBy(xScale: scale, yScale: -scale)
        }
        
        if viewModel.verticallyFlip {
            let scale: CGFloat = viewModel.rotationType.isRotatedByMultiple180 ? 1 : -1
            cropWorkbenchView.transformScaleBy(xScale: scale, yScale: -scale)
        }
    }
    
    func flip(isHorizontal: Bool = true, animated: Bool = true) {
        var scaleX: CGFloat = 1
        var scaleY: CGFloat = 1
        
        if isHorizontal {
            if viewModel.rotationType.isRotatedByMultiple180 {
                scaleX = -scaleX
            } else {
                scaleY = -scaleY
            }
        } else {
            if viewModel.rotationType.isRotatedByMultiple180 {
                scaleY = -scaleY
            } else {
                scaleX = -scaleX
            }
        }
        
        func flip() {
            flipOddTimes.toggle()
            
            let flipTransform = cropWorkbenchView.transform.scaledBy(x: scaleX, y: scaleY)
            let coff: CGFloat = flipOddTimes ? 2 : -2
            cropWorkbenchView.transform = flipTransform.rotated(by: coff*viewModel.radians)
            
            viewModel.degrees *= -1
            // For SlideDial: update the ruler when showing straighten,
            // or silently sync the stored straighten value when on a skew tab.
            // Skew values are kept unchanged on the dial after flip (the
            // effective negation is applied at transform time).
            if let slideDial = rotationControlView as? SlideDial {
                if currentRotationAdjustmentType == .straighten {
                    slideDial.updateRotationValue(by: Angle(degrees: viewModel.degrees))
                } else {
                    slideDial.syncStraightenValue(viewModel.degrees)
                }
            } else {
                rotationControlView?.updateRotationValue(by: Angle(degrees: viewModel.degrees))
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.5) {
                flip()
            }
        } else {
            flip()
        }
    }
    
    func horizontallyFlip() {
        viewModel.horizontallyFlip.toggle()
        flip(isHorizontal: true)
        previousSkewScale = 1.0
        previousSkewInset = .zero
        previousSkewOptimalOffset = nil
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        checkImageStatusChanged()
    }
    
    func verticallyFlip() {
        viewModel.verticallyFlip.toggle()
        flip(isHorizontal: false)
        previousSkewScale = 1.0
        previousSkewInset = .zero
        previousSkewOptimalOffset = nil
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        checkImageStatusChanged()
    }
}
