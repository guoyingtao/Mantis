//
//  CropViewController+CropAPI.swift
//  Mantis
//
//  Extracted from CropViewController.swift
//

import UIKit

// MARK: - Public Crop API
extension CropViewController {
    @available(iOS 13.0, *)
    public func crop(by cropInfo: CropInfo) {
        guard let image = cropView.image.crop(by: cropInfo) else {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.delegate?.cropViewControllerDidFailToCrop(self, original: cropView.image)
            }
            return
        }
        
        let transformation = cropView.makeTransformation()
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            delegate?.cropViewControllerDidCrop(self,
                                                cropped: image,
                                                transformation: transformation,
                                                cropInfo: cropInfo)
        }
    }
        
    public func crop() {
        switch config.cropMode {
        case .sync:
            let cropOutput = cropView.crop()
            handleCropOutput(cropOutput)
        case .async:
            cropView.asyncCrop(completion: handleCropOutput)
        }
        
        func handleCropOutput(_ cropOutput: CropOutput) {
            guard let image = cropOutput.croppedImage else {
                delegate?.cropViewControllerDidFailToCrop(self, original: cropView.image)
                return
            }
            
            delegate?.cropViewControllerDidCrop(self,
                                                cropped: image,
                                                transformation: cropOutput.transformation,
                                                cropInfo: cropOutput.cropInfo)
        }
    }
    
    public func process(_ image: UIImage) -> UIImage? {
        return cropView.crop(image).croppedImage
    }
    
    public func getExpectedCropImageSize() -> CGSize {
        cropView.getExpectedCropImageSize()
    }
    
    public func update(_ image: UIImage) {
        cropView.update(image)
    }
}
