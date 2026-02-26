//
//  CropView+Layout.swift
//  Mantis
//
//  Extracted from CropView.swift
//

import UIKit

// MARK: - Layout & Content Bounds
extension CropView {
    func getContentBounds() -> CGRect {
        let cropViewPadding = cropViewConfig.padding
        
        let rect = self.bounds
        var contentRect = CGRect.zero
        
        var rotationControlViewHeight: CGFloat = 0
        
        if cropViewConfig.showAttachedRotationControlView && rotationControlView?.isAttachedToCropView == true {
            rotationControlViewHeight = slideDialHandlesTypeSelection
                ? max(cropViewConfig.rotationControlViewHeight, 120)
                : cropViewConfig.rotationControlViewHeight
        }
        
        // Add space for rotation type selector if enabled
        // (Only needed for the external text-based selector; SlideDial withTypeSelector
        // embeds its buttons within the rotationControlViewHeight area)
        var rotationTypeSelectorHeight: CGFloat = 0
        if cropViewConfig.enablePerspectiveCorrection && !slideDialHandlesTypeSelection {
            rotationTypeSelectorHeight = 32
        }
        
        if Orientation.treatAsPortrait {
            contentRect.origin.x = rect.origin.x + cropViewPadding
            contentRect.origin.y = rect.origin.y + cropViewPadding
            
            contentRect.size.width = rect.width - 2 * cropViewPadding
            contentRect.size.height = rect.height - 2 * cropViewPadding - rotationControlViewHeight - rotationTypeSelectorHeight
        } else if Orientation.isLandscape {
            contentRect.size.width = rect.width - 2 * cropViewPadding - rotationControlViewHeight - rotationTypeSelectorHeight
            contentRect.size.height = rect.height - 2 * cropViewPadding
            
            contentRect.origin.y = rect.origin.y + cropViewPadding
            if Orientation.isLandscapeRight {
                contentRect.origin.x = rect.origin.x + cropViewPadding
            } else {
                contentRect.origin.x = rect.origin.x + cropViewPadding + rotationControlViewHeight
            }
        }
        
        return contentRect
    }
    
    func getImageLeftTopAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.cropLeftTopOnImage
        }
        
        let leftTopPoint = cropAuxiliaryIndicatorView.convert(CGPoint(x: 0, y: 0), to: imageContainer)
        let point = CGPoint(x: leftTopPoint.x / imageContainer.bounds.width, y: leftTopPoint.y / imageContainer.bounds.height)
        return point
    }
    
    func getImageRightBottomAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.cropRightBottomOnImage
        }
        
        let rightBottomPoint = cropAuxiliaryIndicatorView.convert(CGPoint(x: cropAuxiliaryIndicatorView.bounds.width,
                                                                          y: cropAuxiliaryIndicatorView.bounds.height),
                                                                  to: imageContainer)
        let point = CGPoint(x: rightBottomPoint.x / imageContainer.bounds.width, y: rightBottomPoint.y / imageContainer.bounds.height)
        return point
    }
    
    func saveAnchorPoints() {
        // Temporarily remove the 3D perspective skew so that coordinate
        // conversions between the crop overlay and the image container
        // are purely 2D-affine.  The sublayerTransform includes a
        // compensating scale that distorts convert(_:to:) results,
        // causing progressive zoom drift on every device rotation.
        let savedSublayerTransform = cropWorkbenchView.layer.sublayerTransform
        let hasSkew = viewModel.horizontalSkewDegrees != 0 || viewModel.verticalSkewDegrees != 0
        if hasSkew {
            cropWorkbenchView.layer.sublayerTransform = CATransform3DIdentity
        }
        
        viewModel.cropLeftTopOnImage = getImageLeftTopAnchorPoint()
        viewModel.cropRightBottomOnImage = getImageRightBottomAnchorPoint()
        
        if hasSkew {
            cropWorkbenchView.layer.sublayerTransform = savedSublayerTransform
        }
    }
    
    func adjustUIForNewCrop(contentRect: CGRect,
                            animation: Bool = true,
                            zoom: Bool = true,
                            completion: @escaping () -> Void) {
        
        guard viewModel.cropBoxFrame.size.width > 0 && viewModel.cropBoxFrame.size.height > 0 else {
            return
        }
        
        let scaleX = contentRect.width / viewModel.cropBoxFrame.size.width
        let scaleY = contentRect.height / viewModel.cropBoxFrame.size.height
        
        let scale = min(scaleX, scaleY)
        
        let newCropBounds = CGRect(x: 0, y: 0, width: viewModel.cropBoxFrame.width * scale, height: viewModel.cropBoxFrame.height * scale)
        
        let radians = viewModel.getTotalRadians()
        
        // calculate the new bounds of scroll view
        let newBoundWidth = abs(cos(radians)) * newCropBounds.size.width + abs(sin(radians)) * newCropBounds.size.height
        let newBoundHeight = abs(sin(radians)) * newCropBounds.size.width + abs(cos(radians)) * newCropBounds.size.height
        
        guard newBoundWidth > 0 && newBoundWidth != .infinity
                && newBoundHeight > 0 && newBoundHeight != .infinity else {
            return
        }
        
        // calculate the zoom area of scroll view
        var scaleFrame = viewModel.cropBoxFrame
        
        let refContentWidth = abs(cos(radians)) * cropWorkbenchView.contentSize.width + abs(sin(radians)) * cropWorkbenchView.contentSize.height
        let refContentHeight = abs(sin(radians)) * cropWorkbenchView.contentSize.width + abs(cos(radians)) * cropWorkbenchView.contentSize.height
        
        if scaleFrame.width >= refContentWidth {
            scaleFrame.size.width = refContentWidth
        }
        
        if scaleFrame.height >= refContentHeight {
            scaleFrame.size.height = refContentHeight
        }
        
        let contentOffset = cropWorkbenchView.contentOffset
        let contentOffsetCenter = CGPoint(x: (contentOffset.x + cropWorkbenchView.bounds.width / 2),
                                          y: (contentOffset.y + cropWorkbenchView.bounds.height / 2))
        
        cropWorkbenchView.bounds = CGRect(x: 0, y: 0, width: newBoundWidth, height: newBoundHeight)
        
        let newContentOffset = CGPoint(x: (contentOffsetCenter.x - newBoundWidth / 2),
                                       y: (contentOffsetCenter.y - newBoundHeight / 2))
        cropWorkbenchView.contentOffset = newContentOffset
        
        let newCropBoxFrame = GeometryHelper.getInscribeRect(fromOutsideRect: contentRect, andInsideRect: viewModel.cropBoxFrame)
        
        func updateUI(by newCropBoxFrame: CGRect, and scaleFrame: CGRect) {
            viewModel.cropBoxFrame = newCropBoxFrame
            
            if zoom {
                let zoomRect = convert(scaleFrame,
                                       to: cropWorkbenchView.imageContainer)
                cropWorkbenchView.zoom(to: zoomRect, animated: false)
            }
            cropWorkbenchView.updateContentOffset()
            makeSureImageContainsCropOverlay()
        }
        
        if animation {
            UIView.animate(withDuration: 0.25, animations: {
                updateUI(by: newCropBoxFrame, and: scaleFrame)
            }, completion: {_ in
                completion()
            })
        } else {
            updateUI(by: newCropBoxFrame, and: scaleFrame)
            completion()
        }
        
        isManuallyZoomed = true
    }
    
    func makeSureImageContainsCropOverlay() {
        let hasSkew = viewModel.horizontalSkewDegrees != 0 || viewModel.verticalSkewDegrees != 0

        if hasSkew {
            // When skew is active, UIView.convert does NOT account for the 3D
            // sublayerTransform, so the 2D containment check is unreliable.
            // The perspective compensating scale visually enlarges the image well
            // beyond its 2D frame, meaning the standard check produces false
            // "out of bounds" results that trigger zoomScaleToBound and cause
            // visible jitter. Instead, rely on the content inset constraints
            // (updateContentInsetForSkew / clampContentOffsetForSkewIfNeeded)
            // to keep the overlay inside the projected image.
        } else {
            if !imageContainer.contains(rect: cropAuxiliaryIndicatorView.frame, fromView: self, tolerance: 0.25) {
                cropWorkbenchView.zoomScaleToBound(animated: true)
            }
        }
    }
    
    func adjustWorkbenchView(by radians: CGFloat) {
        let width = abs(cos(radians)) * cropAuxiliaryIndicatorView.frame.width + abs(sin(radians)) * cropAuxiliaryIndicatorView.frame.height
        let height = abs(sin(radians)) * cropAuxiliaryIndicatorView.frame.width + abs(cos(radians)) * cropAuxiliaryIndicatorView.frame.height
        
        cropWorkbenchView.updateLayout(byNewSize: CGSize(width: width, height: height))
        
        if !isManuallyZoomed || cropWorkbenchView.shouldScale() {
            cropWorkbenchView.zoomScaleToBound(animated: false)
            isManuallyZoomed = false
        } else {
            cropWorkbenchView.updateMinZoomScale()
        }
        
        cropWorkbenchView.updateContentOffset()
    }
    
    func updatePositionFor90Rotation(by radians: CGFloat) {
        func adjustScrollViewForNormalRatio(by radians: CGFloat) -> CGFloat {
            let width = abs(cos(radians)) * cropAuxiliaryIndicatorView.frame.width + abs(sin(radians)) * cropAuxiliaryIndicatorView.frame.height
            let height = abs(sin(radians)) * cropAuxiliaryIndicatorView.frame.width + abs(cos(radians)) * cropAuxiliaryIndicatorView.frame.height
            
            let newSize: CGSize
            if viewModel.rotationType.isRotatedByMultiple180 {
                newSize = CGSize(width: width, height: height)
            } else {
                newSize = CGSize(width: height, height: width)
            }
            
            let scale = newSize.width / cropWorkbenchView.bounds.width
            cropWorkbenchView.updateLayout(byNewSize: newSize)
            return scale
        }
        
        let scale = adjustScrollViewForNormalRatio(by: radians)
        
        let newZoomScale = cropWorkbenchView.zoomScale * scale
        cropWorkbenchView.minimumZoomScale = newZoomScale
        cropWorkbenchView.zoomScale = newZoomScale
        
        cropWorkbenchView.updateContentOffset()
    }
    
    func setFixedRatioCropBox(zoom: Bool = true, cropBox: CGRect? = nil) {
        let refCropBox = cropBox ?? getInitialCropBoxRect()
        let imageHorizontalToVerticalRatio = ImageHorizontalToVerticalRatio(ratio: getImageHorizontalToVerticalRatio())
        viewModel.setCropBoxFrame(by: refCropBox, for: imageHorizontalToVerticalRatio)
        
        let contentRect = getContentBounds()
        adjustUIForNewCrop(contentRect: contentRect, animation: false, zoom: zoom) { [weak self] in
            guard let self = self else { return }
            if self.forceFixedRatio {
                self.checkForForceFixedRatioFlag = true
            }
            self.viewModel.setBetweenOperationStatus()
        }
        
        adaptRotationControlViewToCropBoxIfNeeded()
        cropWorkbenchView.updateMinZoomScale()
    }
}
