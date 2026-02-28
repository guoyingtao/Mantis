//
//  CropViewController+CropViewDelegate.swift
//  Mantis
//
//  Extracted from CropViewController.swift
//

import UIKit

// MARK: - CropViewDelegate
extension CropViewController: CropViewDelegate {
    func cropViewDidBecomeResettable(_ cropView: CropViewProtocol) {
        cropToolbar.handleCropViewDidBecomeResettable()
        delegate?.cropViewControllerDidImageTransformed(self, transformation: cropView.makeTransformation())
        delegate?.cropViewController(self, didBecomeResettable: true)
        
        if config.enableUndoRedo {
            guard let previous = previousCropState else { return }
            let userGenerated = isCropStateUserGenerated
            currentCropState = cropView.makeCropState()
            
            if previous != currentCropState {
                TransformStack
                    .shared
                    .pushTransformRecordOntoStack(transformType: .transform,
                                                  previous: previous, current:
                                                    currentCropState,
                                                  userGenerated: userGenerated)
            }
            
            previousCropState = nil
            currentCropState = nil
        }
    }
    
    func cropViewDidBecomeUnResettable(_ cropView: CropViewProtocol) {
        cropToolbar.handleCropViewDidBecomeUnResettable()
        delegate?.cropViewController(self, didBecomeResettable: false)
    }
    
    func cropViewDidBeginResize(_ cropView: CropViewProtocol) {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
        cropToolbar.handleImageNotAutoAdjustable()
        delegate?.cropViewControllerDidBeginResize(self)
    }
    
    func cropViewDidBeginCrop(_ cropView: CropViewProtocol) {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
        delegate?.cropViewControllerDidBeginCrop(self)
    }
    
    func cropViewDidEndCrop(_ cropView: CropViewProtocol) {
        delegate?.cropViewControllerDidEndCrop(self,
                                               original: cropView.image,
                                               cropInfo: cropView.getCropInfo())
    }
    
    func cropViewDidEndResize(_ cropView: CropViewProtocol) {
        delegate?.cropViewControllerDidEndResize(self,
                                                 original: cropView.image,
                                                 cropInfo: cropView.getCropInfo())
    }
}
