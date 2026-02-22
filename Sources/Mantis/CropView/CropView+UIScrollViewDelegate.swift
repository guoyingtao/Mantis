//
//  CropView+UIScrollViewDelegate.swift
//  Mantis
//
//  Created by Echo on 5/24/19.
//

import Foundation
import UIKit

extension CropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageContainer
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.cropViewDidBeginCrop(self)
        viewModel.setTouchImageStatus()
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        // A resize event has begun via gesture on the photo (scrollview), so notify delegate
        delegate?.cropViewDidBeginResize(self)
        viewModel.setTouchImageStatus()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard !scrollView.subviews.isEmpty else {
            return
        }
        
        let subView = scrollView.subviews[0]
        
        let offsetX: CGFloat = max((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0)
        let offsetY: CGFloat = max((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0)
        
        let newCenter = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        guard newCenter.x.isFinite && newCenter.y.isFinite else { return }
        subView.center = newCenter
        
        // When skew is active, recompute the sublayerTransform so the
        // perspective depth scales with zoom and image corners never cross
        // behind the camera plane (w ≤ 0 → NaN layer position).
        let hasSkew = viewModel.horizontalSkewDegrees != 0 || viewModel.verticalSkewDegrees != 0
        if hasSkew {
            applySkewTransformIfNeeded()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        clampContentOffsetForSkewIfNeeded()
        viewModel.setBetweenOperationStatus()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegate?.cropViewDidEndResize(self)
        makeSureImageContainsCropOverlay()
        clampContentOffsetForSkewIfNeeded()

        isManuallyZoomed = true
        viewModel.setBetweenOperationStatus()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            clampContentOffsetForSkewIfNeeded()
            viewModel.setBetweenOperationStatus()
        }
    }
}
