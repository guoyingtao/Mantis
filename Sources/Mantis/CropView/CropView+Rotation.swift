//
//  CropView+Rotation.swift
//  Mantis
//
//  Extracted from CropView.swift
//

import UIKit

// MARK: - Rotation Dial Setup
extension CropView {
    func setupRotationDialIfNeeded() {
        guard let rotationControlView = rotationControlView else {
            return
        }
        
        rotationControlView.reset()
        rotationControlView.isUserInteractionEnabled = true
        
        rotationControlView.didUpdateRotationValue = { [unowned self] angle in
            // Notify delegate on the first frame of each rotation gesture
            // so that previousCropState is captured for undo/redo.
            if self.viewModel.viewStatus != .touchRotationBoard && self.viewModel.viewStatus != .rotating {
                self.delegate?.cropViewDidBeginResize(self)
            }
            self.viewModel.setTouchRotationBoardStatus()
            
            switch self.currentRotationAdjustmentType {
            case .straighten:
                self.viewModel.setRotatingStatus(by: clampAngle(angle))
            case .horizontalSkew:
                let clamped = max(-PerspectiveTransformHelper.maxSkewDegrees,
                                  min(PerspectiveTransformHelper.maxSkewDegrees, -angle.degrees))
                self.viewModel.horizontalSkewDegrees = clamped
                self.applySkewTransformIfNeeded()
                self.updateContentInsetForSkew()
            case .verticalSkew:
                let clamped = max(-PerspectiveTransformHelper.maxSkewDegrees,
                                  min(PerspectiveTransformHelper.maxSkewDegrees, angle.degrees))
                self.viewModel.verticalSkewDegrees = clamped
                self.applySkewTransformIfNeeded()
                self.updateContentInsetForSkew()
            }
        }
        
        rotationControlView.didFinishRotation = { [unowned self] in
            if !self.viewModel.needCrop() {
                self.delegate?.cropViewDidEndResize(self)
            }
            // After rotation ends, recalculate contentInset for the new geometry
            // so panning still works correctly when skew is active.
            self.updateContentInsetForSkew()
            self.makeSureImageContainsCropOverlay()
            self.viewModel.setBetweenOperationStatus()
        }
        
        // Hook up the type switch callback for SlideDial in withTypeSelector mode
        if let slideDial = rotationControlView as? SlideDial {
            slideDial.didSwitchAdjustmentType = { [unowned self] newType in
                self.currentRotationAdjustmentType = newType
                
                // Notify that rotation finished so CropView settles layout
                if !self.viewModel.needCrop() {
                    self.delegate?.cropViewDidEndResize(self)
                }
                // When switching between skew axes (e.g. H→V), the current
                // pan position may be invalid for the combined geometry that
                // the next axis adjustment will produce. Clamp now to prevent
                // the overlay from starting outside the image.
                self.clampContentOffsetForSkewIfNeeded()
                self.viewModel.setBetweenOperationStatus()
            }
        }
        
        if rotationControlView.isAttachedToCropView {
            let boardLength = min(bounds.width, bounds.height) * rotationControlView.getLengthRatio()
            // withTypeSelector mode needs more height for the circular buttons above the ruler
            let controlHeight: CGFloat = slideDialHandlesTypeSelection
                ? max(cropViewConfig.rotationControlViewHeight, 120)
                : cropViewConfig.rotationControlViewHeight
            let dialFrame = CGRect(x: 0,
                                   y: 0,
                                   width: boardLength,
                                   height: controlHeight)
            
            rotationControlView.setupUI(withAllowableFrame: dialFrame)
        }
        
        if let rotationDial = rotationControlView as? RotationDialProtocol {
            rotationDial.setRotationCenter(by: cropAuxiliaryIndicatorView.center, of: self)
        }
        
        rotationControlView.updateRotationValue(by: Angle(radians: viewModel.radians))
        viewModel.setBetweenOperationStatus()
        
        adaptRotationControlViewToCropBoxIfNeeded()
        rotationControlView.bringSelfToFront()
        
        // Set up rotation type selector if enabled
        setupRotationTypeSelector()
    }
    
    func adaptRotationControlViewToCropBoxIfNeeded() {
        guard let rotationControlView = rotationControlView,
              rotationControlView.isAttachedToCropView else { return }
        
        if Orientation.treatAsPortrait {
            rotationControlView.transform = CGAffineTransform(rotationAngle: 0)
            rotationControlView.frame.origin.x = cropAuxiliaryIndicatorView.frame.origin.x +
            (cropAuxiliaryIndicatorView.frame.width - rotationControlView.frame.width) / 2
            rotationControlView.frame.origin.y = cropAuxiliaryIndicatorView.frame.maxY
        } else if Orientation.isLandscapeRight {
            rotationControlView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            rotationControlView.frame.origin.x = cropAuxiliaryIndicatorView.frame.maxX
            rotationControlView.frame.origin.y = cropAuxiliaryIndicatorView.frame.origin.y +
            (cropAuxiliaryIndicatorView.frame.height - rotationControlView.frame.height) / 2
        } else if Orientation.isLandscapeLeft {
            rotationControlView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            rotationControlView.frame.origin.x = cropAuxiliaryIndicatorView.frame.minX - rotationControlView.frame.width
            rotationControlView.frame.origin.y = cropAuxiliaryIndicatorView.frame.origin.y +
            (cropAuxiliaryIndicatorView.frame.height - rotationControlView.frame.height) / 2
        }
        
        rotationControlView.handleDeviceRotation()
    }
}

// MARK: - 90° Rotation
extension CropView {
    func rotateBy90(withRotateType rotateType: RotateBy90DegreeType, completion: @escaping () -> Void = {}) {
        viewModel.setDegree90RotatingStatus()
        
        var newRotateType = rotateType
        
        if viewModel.horizontallyFlip {
            newRotateType.toggle()
        }
        
        if viewModel.verticallyFlip {
            newRotateType.toggle()
        }
        
        // Save skew state and reset to identity before rotation
        let savedHSkew = viewModel.horizontalSkewDegrees
        let savedVSkew = viewModel.verticalSkewDegrees
        let hadSkew = savedHSkew != 0 || savedVSkew != 0
        
        // Temporarily zero out skew so the rotation animation and geometry
        // calculations work purely in 2D, without 3D perspective interference.
        if hadSkew {
            viewModel.horizontalSkewDegrees = 0
            viewModel.verticalSkewDegrees = 0
            cropWorkbenchView.layer.sublayerTransform = CATransform3DIdentity
        }
        
        func handleRotateAnimation() {
            if cropViewConfig.rotateCropBoxFor90DegreeRotation {
                var rect = cropAuxiliaryIndicatorView.frame
                rect.size.width = cropAuxiliaryIndicatorView.frame.height
                rect.size.height = cropAuxiliaryIndicatorView.frame.width
                
                let newRect = GeometryHelper.getInscribeRect(fromOutsideRect: getContentBounds(), andInsideRect: rect)
                viewModel.cropBoxFrame = newRect
            }
            
            let rotateAngle = newRotateType == .clockwise ? CGFloat.pi / 2 : -CGFloat.pi / 2
            cropWorkbenchView.transform = cropWorkbenchView.transform.rotated(by: rotateAngle)
            
            if cropViewConfig.rotateCropBoxFor90DegreeRotation {
                updatePositionFor90Rotation(by: rotateAngle + viewModel.radians)
            } else {
                adjustWorkbenchView(by: rotateAngle + viewModel.radians)
            }
            
            // Restore skew inside the animation block so it transitions smoothly
            // instead of jumping back abruptly in the completion handler.
            if hadSkew {
                viewModel.horizontalSkewDegrees = savedHSkew
                viewModel.verticalSkewDegrees = savedVSkew
                skewState.reset()
                applySkewTransformIfNeeded()
                updateContentInsetForSkew()
            }
        }
        
        func handleRotateCompletion() {
            cropWorkbenchView.updateMinZoomScale()
            viewModel.rotateBy90(withRotateType: newRotateType)
            
            // Ensure skew values are set (they were restored during animation,
            // but rotateBy90 above may affect geometry, so re-apply).
            viewModel.horizontalSkewDegrees = savedHSkew
            viewModel.verticalSkewDegrees = savedVSkew
            
            if viewModel.horizontalSkewDegrees != 0 || viewModel.verticalSkewDegrees != 0 {
                skewState.reset()
                applySkewTransformIfNeeded()
                updateContentInsetForSkew()
            }
            
            // Keep the SlideDial's stored angles in sync.
            syncSlideDialSkewValues()
            
            viewModel.setBetweenOperationStatus()
            completion()
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            handleRotateAnimation()
        }, completion: { _ in
            handleRotateCompletion()
        })
    }
    
    func handleAlterCropper90Degree() {
        let ratio = Double(cropAuxiliaryIndicatorView.frame.height / cropAuxiliaryIndicatorView.frame.width)
        
        viewModel.fixedImageRatio = CGFloat(ratio)
        
        UIView.animate(withDuration: 0.5) {
            self.setFixedRatioCropBox()
        }
    }
    
    func rotate(by angle: Angle) {
        viewModel.setRotatingStatus(by: angle)
        rotationControlView?.updateRotationValue(by: angle)
    }
}

// MARK: - RotationTypeSelectorDelegate
extension CropView: RotationTypeSelectorDelegate {
    func rotationTypeSelector(_ selector: RotationTypeSelector,
                              didSelectType type: RotationAdjustmentType) {
        // Save the current dial value for the previous mode before switching
        let previousType = currentRotationAdjustmentType
        if let currentDialValue = rotationControlView?.getTotalRotationValue() {
            switch previousType {
            case .straighten:
                viewModel.degrees = currentDialValue
            case .horizontalSkew:
                viewModel.horizontalSkewDegrees = currentDialValue
            case .verticalSkew:
                viewModel.verticalSkewDegrees = currentDialValue
            }
        }
        
        currentRotationAdjustmentType = type
        
        // Reset the dial and set it to the stored value for the new mode
        rotationControlView?.reset()
        switch type {
        case .straighten:
            rotationControlView?.updateRotationValue(by: Angle(degrees: viewModel.degrees))
        case .horizontalSkew:
            rotationControlView?.updateRotationValue(by: Angle(degrees: viewModel.horizontalSkewDegrees))
        case .verticalSkew:
            rotationControlView?.updateRotationValue(by: Angle(degrees: viewModel.verticalSkewDegrees))
        }
    }
    
    /// Sets up the rotation type selector below the rotation dial.
    /// When SlideDial is in withTypeSelector mode, the selector is built-in, so skip the external one.
    func setupRotationTypeSelector() {
        guard cropViewConfig.enablePerspectiveCorrection else { return }
        
        // If SlideDial handles type selection internally, hide the old external selector
        if let slideDial = rotationControlView as? SlideDial,
           case .withTypeSelector = slideDial.config.mode {
            rotationTypeSelector.isHidden = true
            rotationTypeSelector.removeFromSuperview()
            return
        }
        
        if rotationTypeSelector.superview == nil {
            addSubview(rotationTypeSelector)
        }
        
        rotationTypeSelector.isUserInteractionEnabled = true
        rotationTypeSelector.isHidden = false
        layoutRotationTypeSelector()
        rotationTypeSelector.bringSelfToFront()
    }
    
    func layoutRotationTypeSelector() {
        guard cropViewConfig.enablePerspectiveCorrection,
              rotationTypeSelector.superview != nil else { return }
        
        let selectorWidth: CGFloat = 220
        let selectorHeight: CGFloat = 28
        
        if Orientation.treatAsPortrait {
            if let rotationView = rotationControlView, rotationView.isAttachedToCropView {
                rotationTypeSelector.frame = CGRect(
                    x: rotationView.frame.midX - selectorWidth / 2,
                    y: rotationView.frame.maxY + 4,
                    width: selectorWidth,
                    height: selectorHeight
                )
            } else {
                rotationTypeSelector.frame = CGRect(
                    x: cropAuxiliaryIndicatorView.frame.midX - selectorWidth / 2,
                    y: cropAuxiliaryIndicatorView.frame.maxY + cropViewConfig.rotationControlViewHeight + 4,
                    width: selectorWidth,
                    height: selectorHeight
                )
            }
        } else {
            // Landscape: position beside the crop area
            rotationTypeSelector.frame = CGRect(
                x: cropAuxiliaryIndicatorView.frame.midX - selectorWidth / 2,
                y: cropAuxiliaryIndicatorView.frame.maxY + cropViewConfig.rotationControlViewHeight + 4,
                width: selectorWidth,
                height: selectorHeight
            )
        }
    }
}
