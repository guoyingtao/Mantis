//
//  CropView+Crop.swift
//  Mantis
//
//  Extracted from CropView.swift
//

import UIKit

// MARK: - Crop Output
extension CropView {
    func asyncCrop(_ image: UIImage, completion: @escaping (CropOutput) -> Void) {
        let cropInfo = getCropInfo()
        let cropOutput = (image.crop(by: cropInfo), makeTransformation(), cropInfo)
        
        DispatchQueue.global(qos: .userInteractive).async {
            let maskedCropOutput = self.addImageMask(to: cropOutput)
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                completion(maskedCropOutput)
            }
        }
    }
    
    public func makeCropState() -> CropState {
        return CropState(
            rotationType: viewModel.rotationType,
            degrees: viewModel.degrees,
            aspectRatioLockEnabled: aspectRatioLockEnabled,
            aspectRato: viewModel.fixedImageRatio,
            flipOddTimes: flipOddTimes,
            transformation: makeTransformation(),
            horizontalSkewDegrees: viewModel.horizontalSkewDegrees,
            verticalSkewDegrees: viewModel.verticalSkewDegrees
        )
    }
    
    func makeTransformation() -> Transformation {
        Transformation(
            offset: cropWorkbenchView.contentOffset,
            rotation: getTotalRadians(),
            scale: cropWorkbenchView.zoomScale,
            isManuallyZoomed: isManuallyZoomed,
            initialMaskFrame: getInitialCropBoxRect(),
            maskFrame: cropAuxiliaryIndicatorView.frame,
            cropWorkbenchViewBounds: cropWorkbenchView.bounds,
            horizontallyFlipped: viewModel.horizontallyFlip,
            verticallyFlipped: viewModel.verticallyFlip,
            horizontalSkewDegrees: viewModel.horizontalSkewDegrees,
            verticalSkewDegrees: viewModel.verticalSkewDegrees
        )
    }
    
    func addImageMask(to cropOutput: CropOutput) -> CropOutput {
        let (croppedImage, transformation, cropInfo) = cropOutput
        
        guard let croppedImage = croppedImage else {
            assertionFailure("croppedImage should not be nil")
            return cropOutput
        }
        
        switch cropViewConfig.cropShapeType {
        case .rect,
                .square,
                .circle(maskOnly: true),
                .roundedRect(_, maskOnly: true),
                .path(_, maskOnly: true),
                .diamond(maskOnly: true),
                .heart(maskOnly: true),
                .polygon(_, _, maskOnly: true):
            
            let outputImage: UIImage?
            if cropViewConfig.cropBorderWidth > 0 {
                outputImage = croppedImage.rectangleMasked(borderWidth: cropViewConfig.cropBorderWidth,
                                                           borderColor: cropViewConfig.cropBorderColor)
            } else {
                outputImage = croppedImage
            }
            
            return (outputImage, transformation, cropInfo)
        case .ellipse:
            return (croppedImage.ellipseMasked(borderWidth: cropViewConfig.cropBorderWidth,
                                               borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .circle:
            return (croppedImage.ellipseMasked(borderWidth: cropViewConfig.cropBorderWidth,
                                               borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .roundedRect(let radiusToShortSide, maskOnly: false):
            let radius = min(croppedImage.size.width, croppedImage.size.height) * radiusToShortSide
            return (croppedImage.roundRect(radius,
                                           borderWidth: cropViewConfig.cropBorderWidth,
                                           borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .path(let points, maskOnly: false):
            return (croppedImage.clipPath(points,
                                          borderWidth: cropViewConfig.cropBorderWidth,
                                          borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .diamond(maskOnly: false):
            let points = [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)]
            return (croppedImage.clipPath(points,
                                          borderWidth: cropViewConfig.cropBorderWidth,
                                          borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .heart(maskOnly: false):
            return (croppedImage.heart(borderWidth: cropViewConfig.cropBorderWidth,
                                       borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .polygon(let sides, let offset, maskOnly: false):
            let points = polygonPointArray(sides: sides, originX: 0.5, originY: 0.5, radius: 0.5, offset: 90 + offset)
            return (croppedImage.clipPath(points,
                                          borderWidth: cropViewConfig.cropBorderWidth,
                                          borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        }
    }
    
    func getTotalRadians() -> CGFloat {
        return viewModel.getTotalRadians()
    }
    
    func getCropInfo() -> CropInfo {
        let rect = imageContainer.convert(imageContainer.bounds,
                                          to: self)
        let point = rect.center
        let zeroPoint = cropAuxiliaryIndicatorView.center
        
        let translation =  CGPoint(x: (point.x - zeroPoint.x), y: (point.y - zeroPoint.y))
        
        var scaleX = cropWorkbenchView.zoomScale
        var scaleY = cropWorkbenchView.zoomScale
        
        if viewModel.horizontallyFlip {
            if viewModel.rotationType.isRotatedByMultiple180 {
                scaleX = -scaleX
            } else {
                scaleY = -scaleY
            }
        }
        
        if viewModel.verticallyFlip {
            if viewModel.rotationType.isRotatedByMultiple180 {
                scaleY = -scaleY
            } else {
                scaleX = -scaleX
            }
        }
        
        let totalRadians = getTotalRadians()
        let cropRegion = imageContainer.getCropRegion(withCropBoxFrame: viewModel.cropBoxFrame,
                                                      cropView: self)
        
        return CropInfo(
            translation: translation,
            rotation: totalRadians,
            scaleX: scaleX,
            scaleY: scaleY,
            cropSize: cropAuxiliaryIndicatorView.frame.size,
            imageViewSize: imageContainer.bounds.size,
            cropRegion: cropRegion,
            horizontalSkewDegrees: viewModel.horizontalSkewDegrees,
            verticalSkewDegrees: viewModel.verticalSkewDegrees,
            skewSublayerTransform: cropWorkbenchView.layer.sublayerTransform,
            scrollContentOffset: cropWorkbenchView.contentOffset,
            scrollBoundsSize: cropWorkbenchView.bounds.size,
            imageContainerFrame: imageContainer.frame,
            scrollViewTransform: cropWorkbenchView.transform
        )
    }
    
    func getExpectedCropImageSize() -> CGSize {
        image.getOutputCropImageSize(by: getCropInfo())
    }
}
