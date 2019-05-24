//
//  CropView+Touches.swift
//  Mantis
//
//  Created by Echo on 5/24/19.
//

import Foundation

extension CropView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let p = self.convert(point, to: self)
        
        if rotationDial.frame.contains(p) {
            return rotationDial
        }
        
        if (gridOverlayView.frame.insetBy(dx: -hotAreaUnit,
                                          dy: -hotAreaUnit).contains(p) &&
            !gridOverlayView.frame.insetBy(dx: hotAreaUnit,
                                           dy: hotAreaUnit).contains(p)
            ) {
            return self
        }
        
        if self.bounds.contains(p) {
            return self.scrollView
        }
        
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard touches.count == 1, let touch = touches.first else {
            return
        }
        
        if touch.view is RotationDial {
            return
        }
        
        viewModel.setTouchImageStatus()
        
        let point = touch.location(in: self)
        
        panOriginPoint = point
        cropOrignFrame = cropBoxFrame
        
        tappedEdge = cropEdge(forPoint: point)
        
        if tappedEdge != .none {
            viewModel.setTouchCropboxHandleStatus()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard touches.count == 1, let touch = touches.first else {
            return
        }
        
        let point = touch.location(in: self)
        updateCropBoxFrame(withTouchPoint: point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if !cropOrignFrame.equalTo(cropBoxFrame) {
            let contentRect = getContentBounds()
            adjustUIForNewCrop(contentRect: contentRect) {[weak self] in
                self?.viewModel.setBetweenOperationStatus()
            }
        } else {
            viewModel.setBetweenOperationStatus()
        }
    }
}

