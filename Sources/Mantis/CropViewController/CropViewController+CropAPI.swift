//
//  CropViewController+CropAPI.swift
//  Mantis
//
//  Extracted from CropViewController.swift
//

import CoreImage
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
            self.deliverCropResult(image: image,
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

            deliverCropResult(image: image,
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

// MARK: - Face Validation
extension CropViewController {
    func deliverCropResult(image: UIImage, transformation: Transformation, cropInfo: CropInfo) {
        guard config.faceValidationConfig.enabled else {
            delegate?.cropViewControllerDidCrop(self,
                                                cropped: image,
                                                transformation: transformation,
                                                cropInfo: cropInfo)
            return
        }

        let accuracy = config.faceValidationConfig.detectorAccuracy.ciAccuracy

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let hasFace = Self.detectFace(in: image, accuracy: accuracy)
            DispatchQueue.main.async {
                guard let self = self else { return }
                if hasFace {
                    self.delegate?.cropViewControllerDidCrop(self,
                                                             cropped: image,
                                                             transformation: transformation,
                                                             cropInfo: cropInfo)
                } else {
                    self.delegate?.cropViewControllerDidFailFaceValidation(self, cropped: image)
                }
            }
        }
    }

    private static func detectFace(in image: UIImage, accuracy: String) -> Bool {
        guard let ciImage = CIImage(image: image) else { return true }
        guard let detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: nil,
            options: [CIDetectorAccuracy: accuracy]
        ) else {
            return true
        }
        let orientation = image.imageOrientation.exifOrientation
        let features = detector.features(in: ciImage,
                                         options: [CIDetectorImageOrientation: orientation])
        return !features.isEmpty
    }
}

// MARK: - EXIF Orientation
private extension UIImage.Orientation {
    var exifOrientation: Int {
        switch self {
        case .up: return 1
        case .upMirrored: return 2
        case .down: return 3
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .right: return 6
        case .rightMirrored: return 7
        case .left: return 8
        @unknown default: return 1
        }
    }
}
