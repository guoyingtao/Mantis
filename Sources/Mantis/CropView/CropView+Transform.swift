//
//  CropView+Transform.swift
//  Mantis
//
//  Extracted from CropView.swift
//

import UIKit

// MARK: - Transform Restoration
extension CropView {
    func handlePresetFixedRatio(_ ratio: Double, transformation: Transformation) {
        aspectRatioLockEnabled = true
        
        if ratio == 0 {
            viewModel.fixedImageRatio = transformation.maskFrame.width / transformation.maskFrame.height
        } else {
            viewModel.fixedImageRatio = CGFloat(ratio)
            setFixedRatioCropBox(zoom: false, cropBox: viewModel.cropBoxFrame)
        }
    }
    
    func setFreeCrop() {
        aspectRatioLockEnabled = false
        viewModel.fixedImageRatio = -1
    }
    
    public func applyCropState(with cropState: CropState) {
        viewModel.rotationType = .none
        viewModel.horizontallyFlip = cropState.transformation.horizontallyFlipped
        viewModel.verticallyFlip = cropState.transformation.verticallyFlipped
        viewModel.fixedImageRatio = cropState.aspectRato
        viewModel.horizontalSkewDegrees = cropState.horizontalSkewDegrees
        viewModel.verticalSkewDegrees = cropState.verticalSkewDegrees
        flipOddTimes = cropState.flipOddTimes
        
        var newTransform = getTransformInfo(byTransformInfo: cropState.transformation)
        
        if flipOddTimes {
            let localRotation = newTransform.rotation.truncatingRemainder(dividingBy: .pi/2)
            let rotation90s = newTransform.rotation - localRotation
            newTransform.rotation = -rotation90s + localRotation
        }
        
        if newTransform.maskFrame != .zero {
             viewModel.cropBoxFrame = newTransform.maskFrame
        }
        
        transform(byTransformInfo: newTransform)
        
        viewModel.degrees = cropState.degrees
        viewModel.rotationType = cropState.rotationType
        aspectRatioLockEnabled = cropState.aspectRatioLockEnabled
        
        // Restore skew transforms
        skewState.reset()
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        syncSlideDialSkewValues()
    }
    
    func transform(byTransformInfo transformation: Transformation, isUpdateRotationControlView: Bool = true) {
        
        viewModel.setRotatingStatus(by: Angle(radians: transformation.rotation))
        
        if transformation.cropWorkbenchViewBounds != .zero {
            cropWorkbenchView.bounds = transformation.cropWorkbenchViewBounds
        }
        
        isManuallyZoomed = transformation.isManuallyZoomed
        cropWorkbenchView.zoomScale = transformation.scale
        cropWorkbenchView.contentOffset = transformation.offset
        
        viewModel.setBetweenOperationStatus()
        
        if transformation.maskFrame != .zero {
            viewModel.cropBoxFrame = transformation.maskFrame
        }
        
        // Restore skew values
        viewModel.horizontalSkewDegrees = transformation.horizontalSkewDegrees
        viewModel.verticalSkewDegrees = transformation.verticalSkewDegrees
        skewState.reset()
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        
        if isUpdateRotationControlView {
            rotationControlView?.updateRotationValue(by: Angle(radians: viewModel.radians))
            adaptRotationControlViewToCropBoxIfNeeded()
        }
    }
    
    func getTransformInfo(byTransformInfo transformInfo: Transformation) -> Transformation {
        let cropFrame = viewModel.cropBoxOriginFrame
        let contentBound = getContentBounds()
        
        let adjustScale: CGFloat
        var maskFrameWidth: CGFloat
        var maskFrameHeight: CGFloat
        
        if transformInfo.maskFrame.height / transformInfo.maskFrame.width >= contentBound.height / contentBound.width {
            
            maskFrameHeight = contentBound.height
            maskFrameWidth = transformInfo.maskFrame.width / transformInfo.maskFrame.height * maskFrameHeight
            adjustScale = maskFrameHeight / transformInfo.maskFrame.height
            
        } else {
            
            maskFrameWidth = contentBound.width
            maskFrameHeight = transformInfo.maskFrame.height / transformInfo.maskFrame.width * maskFrameWidth
            adjustScale = maskFrameWidth / transformInfo.maskFrame.width
            
        }
        
        var newTransform = transformInfo
        
        newTransform.offset = CGPoint(x: transformInfo.offset.x * adjustScale,
                                      y: transformInfo.offset.y * adjustScale)
        
        newTransform.maskFrame = CGRect(x: cropFrame.origin.x + (cropFrame.width - maskFrameWidth) / 2,
                                        y: cropFrame.origin.y + (cropFrame.height - maskFrameHeight) / 2,
                                        width: maskFrameWidth,
                                        height: maskFrameHeight)
        newTransform.cropWorkbenchViewBounds = CGRect(x: transformInfo.cropWorkbenchViewBounds.origin.x * adjustScale,
                                                      y: transformInfo.cropWorkbenchViewBounds.origin.y * adjustScale,
                                                      width: transformInfo.cropWorkbenchViewBounds.width * adjustScale,
                                                      height: transformInfo.cropWorkbenchViewBounds.height * adjustScale)
        
        return newTransform
    }
    
    func getTransformInfo(byNormalizedInfo normalizedInfo: CGRect) -> Transformation {
        let cropFrame = viewModel.cropBoxFrame
        
        let scale: CGFloat = min(1/normalizedInfo.width, 1/normalizedInfo.height)
        
        var offset = cropFrame.origin
        offset.x = cropFrame.width * normalizedInfo.origin.x * scale
        offset.y = cropFrame.height * normalizedInfo.origin.y * scale
        
        var maskFrame = cropFrame
        
        if normalizedInfo.width > normalizedInfo.height {
            let adjustScale = 1 / normalizedInfo.width
            maskFrame.size.height = normalizedInfo.height * cropFrame.height * adjustScale
            maskFrame.origin.y += (cropFrame.height - maskFrame.height) / 2
        } else if normalizedInfo.width < normalizedInfo.height {
            let adjustScale = 1 / normalizedInfo.height
            maskFrame.size.width = normalizedInfo.width * cropFrame.width * adjustScale
            maskFrame.origin.x += (cropFrame.width - maskFrame.width) / 2
        }
        
        let isManuallyZoomed = (scale != 1.0)
        let transformation = Transformation(offset: offset,
                                            rotation: 0,
                                            scale: scale,
                                            isManuallyZoomed: isManuallyZoomed,
                                            initialMaskFrame: .zero,
                                            maskFrame: maskFrame,
                                            cropWorkbenchViewBounds: .zero,
                                            horizontallyFlipped: viewModel.horizontallyFlip,
                                            verticallyFlipped: viewModel.verticallyFlip)
        return transformation
    }
    
    func processPresetTransformation(completion: (Transformation) -> Void) {
        switch cropViewConfig.presetTransformationType {
        case .presetInfo(let transformInfo):
            viewModel.horizontallyFlip = transformInfo.horizontallyFlipped
            viewModel.verticallyFlip = transformInfo.verticallyFlipped
            
            if transformInfo.horizontallyFlipped {
                flipOddTimes.toggle()
            }
            
            if transformInfo.verticallyFlipped {
                flipOddTimes.toggle()
            }
            
            var newTransform = getTransformInfo(byTransformInfo: transformInfo)
            
            // The first transform is just for retrieving the final cropBoxFrame
            transform(byTransformInfo: newTransform, isUpdateRotationControlView: false)
            
            // The second transform is for adjusting the scale of transformInfo
            let adjustScale = (viewModel.cropBoxFrame.width / viewModel.cropBoxOriginFrame.width)
            / (transformInfo.maskFrame.width / transformInfo.initialMaskFrame.width)
            newTransform.scale *= adjustScale
            transform(byTransformInfo: newTransform)
            syncSlideDialSkewValues()
            completion(transformInfo)
        case .presetNormalizedInfo(let normalizedInfo):
            let transformInfo = getTransformInfo(byNormalizedInfo: normalizedInfo)
            transform(byTransformInfo: transformInfo)
            cropWorkbenchView.frame = transformInfo.maskFrame
            syncSlideDialSkewValues()
            completion(transformInfo)
        case .none:
            break
        }
    }
}
