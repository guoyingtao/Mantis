//
//  Mantis.swift
//  Mantis
//
//  Created by Yingtao Guo on 11/3/18.
//  Copyright © 2018 Echo Studio. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

// MARK: - APIs
public func cropViewController(image: UIImage,
                               config: Mantis.Config = Mantis.Config(),
                               cropToolbar: CropToolbarProtocol = CropToolbar(frame: .zero),
                               rotationControlView: RotationControlViewProtocol? = nil) -> Mantis.CropViewController {
    let cropViewController = CropViewController(config: config)
    cropViewController.cropView = buildCropView(withImage: image,
                                                config: config.cropViewConfig,
                                                rotationControlView: rotationControlView)
    cropViewController.cropToolbar = cropToolbar
    return cropViewController
}

public func cropViewController<T: CropViewController>(image: UIImage,
                                                      config: Mantis.Config = Mantis.Config(),
                                                      cropToolbar: CropToolbarProtocol = CropToolbar(frame: .zero),
                                                      rotationControlView: RotationControlViewProtocol? = nil) -> T {
    let cropViewController = T(config: config)
    cropViewController.cropView = buildCropView(withImage: image,
                                                config: config.cropViewConfig,
                                                rotationControlView: rotationControlView)
    cropViewController.cropToolbar = cropToolbar
    return cropViewController
}

public func setupCropViewController(_ cropViewController: Mantis.CropViewController,
                                    with image: UIImage,
                                    and config: Mantis.Config = Mantis.Config(),
                                    cropToolbar: CropToolbarProtocol = CropToolbar(frame: .zero),
                                    rotationControlView: RotationControlViewProtocol? = nil) {
    cropViewController.config = config
    cropViewController.cropView = buildCropView(withImage: image,
                                                config: config.cropViewConfig,
                                                rotationControlView: rotationControlView)
    cropViewController.cropToolbar = cropToolbar
}

public func locateResourceBundle(by hostClass: AnyClass) {
    LocalizedHelper.setBundle(Bundle(for: hostClass))
}

public func crop(image: UIImage, by cropInfo: CropInfo) -> UIImage? {
    return image.crop(by: cropInfo)
}

public struct Language {
    var code: String
    
    public init(code: String) {
        self.code = code
    }
}

public func chooseLanguage(_ language: Language) {
    Mantis.Config.language = language
}

public func resetLanguage() {
    Mantis.Config.language = nil
}

// MARK: - internal section
var localizationConfig = LocalizationConfig()

// MARK: - private section
private(set) var bundle: Bundle? = {
    return Mantis.Config.bundle
}()

private func buildCropView(withImage image: UIImage,
                           config cropViewConfig: CropViewConfig,
                           rotationControlView: RotationControlViewProtocol?) -> CropViewProtocol {
    let cropAuxiliaryIndicatorView = CropAuxiliaryIndicatorView(frame: .zero,
                                                                config: cropViewConfig.cropAuxiliaryIndicatorConfig)
    let imageContainer = ImageContainer(image: image)
    let cropView = CropView(image: image,
                            cropViewConfig: cropViewConfig,
                            viewModel: buildCropViewModel(with: cropViewConfig),
                            cropAuxiliaryIndicatorView: cropAuxiliaryIndicatorView,
                            imageContainer: imageContainer,
                            cropWorkbenchView: buildCropWorkbenchView(with: cropViewConfig, and: imageContainer),
                            cropMaskViewManager: buildCropMaskViewManager(with: cropViewConfig))
    
    setupRotationControlViewIfNeeded(withConfig: cropViewConfig, cropView: cropView, rotationControlView: rotationControlView)
    return cropView
}

private func buildCropViewModel(with cropViewConfig: CropViewConfig) -> CropViewModelProtocol {
    CropViewModel(
        cropViewPadding: cropViewConfig.padding,
        hotAreaUnit: cropViewConfig.cropAuxiliaryIndicatorConfig.cropBoxHotAreaUnit
    )
}

private func buildCropWorkbenchView(with cropViewConfig: CropViewConfig, and imageContainer: ImageContainerProtocol) -> CropWorkbenchViewProtocol {
    CropWorkbenchView(frame: .zero,
                   minimumZoomScale: cropViewConfig.minimumZoomScale,
                   maximumZoomScale: cropViewConfig.maximumZoomScale,
                   imageContainer: imageContainer)
}

private func buildCropMaskViewManager(with cropViewConfig: CropViewConfig) -> CropMaskViewManagerProtocol {
    
    let dimmingView = CropDimmingView(cropShapeType: cropViewConfig.cropShapeType)
    
    let visualEffectView = CropMaskVisualEffectView(cropShapeType: cropViewConfig.cropShapeType,
                                                    effectType: cropViewConfig.cropMaskVisualEffectType)
    
    if let color = cropViewConfig.backgroundColor {
        dimmingView.overLayerFillColor = color.cgColor
        visualEffectView.overLayerFillColor = color.cgColor
    }
    
    return CropMaskViewManager(dimmingView: dimmingView, visualEffectView: visualEffectView)
}

private func setupRotationControlViewIfNeeded(withConfig cropViewConfig: CropViewConfig,
                                              cropView: CropView,
                                              rotationControlView: RotationControlViewProtocol?) {
    if let rotationControlView = rotationControlView {
        if rotationControlView.isAttachedToCropView == false ||
            rotationControlView.isAttachedToCropView && cropViewConfig.showAttachedRotationControlView {
            cropView.rotationControlView = rotationControlView
        }
    } else {
        if cropViewConfig.showAttachedRotationControlView {
            switch cropViewConfig.builtInRotationControlViewType {
            case .rotationDial(let config):
                let viewModel = RotationDialViewModel()
                let dialPlate = RotationDialPlate(frame: .zero, config: config)
                cropView.rotationControlView = RotationDial(frame: .zero,
                                                            config: config,
                                                            viewModel: viewModel,
                                                            dialPlate: dialPlate)
            case .slideDial(let config):
                let viewModel = SlideDialViewModel()
                let slideRuler = SlideRuler(frame: .zero, config: config)
                cropView.rotationControlView = SlideDial(frame: .zero,
                                                         config: config,
                                                         viewModel: viewModel,
                                                         slideRuler: slideRuler)
            }
        }
    }
}
