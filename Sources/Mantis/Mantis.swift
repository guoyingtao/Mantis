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
    var resolvedConfig = config
    applyAppearanceDefaults(to: &resolvedConfig)
    let cropViewController = CropViewController(config: resolvedConfig)
    cropViewController.cropView = buildCropView(withImage: image,
                                                config: resolvedConfig.cropViewConfig,
                                                rotationControlView: rotationControlView)
    cropViewController.cropToolbar = cropToolbar
    return cropViewController
}

public func cropViewController<T: CropViewController>(image: UIImage,
                                                      config: Mantis.Config = Mantis.Config(),
                                                      cropToolbar: CropToolbarProtocol = CropToolbar(frame: .zero),
                                                      rotationControlView: RotationControlViewProtocol? = nil) -> T {
    var resolvedConfig = config
    applyAppearanceDefaults(to: &resolvedConfig)
    let cropViewController = T(config: resolvedConfig)
    cropViewController.cropView = buildCropView(withImage: image,
                                                config: resolvedConfig.cropViewConfig,
                                                rotationControlView: rotationControlView)
    cropViewController.cropToolbar = cropToolbar
    return cropViewController
}

public func setupCropViewController(_ cropViewController: Mantis.CropViewController,
                                    with image: UIImage,
                                    and config: Mantis.Config = Mantis.Config(),
                                    cropToolbar: CropToolbarProtocol = CropToolbar(frame: .zero),
                                    rotationControlView: RotationControlViewProtocol? = nil) {
    var resolvedConfig = config
    applyAppearanceDefaults(to: &resolvedConfig)
    cropViewController.config = resolvedConfig
    cropViewController.cropView = buildCropView(withImage: image,
                                                config: resolvedConfig.cropViewConfig,
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

private func applyAppearanceDefaults(to config: inout Mantis.Config) {
    let mode = config.appearanceMode
    
    // Propagate appearance mode to internal configs
    config.cropViewConfig.appearanceMode = mode
    
    // For forceDark, all defaults already match — no changes needed
    guard mode != .forceDark else { return }
    
    // CropToolbarConfig
    config.cropToolbarConfig.backgroundColor = AppearanceColorPreset.toolbarBackground(for: mode)
    config.cropToolbarConfig.foregroundColor = AppearanceColorPreset.toolbarForeground(for: mode)
    
    // CropMaskVisualEffectType (only if user hasn't set a custom backgroundColor)
    if config.cropViewConfig.backgroundColor == nil {
        config.cropViewConfig.cropMaskVisualEffectType = AppearanceColorPreset.maskVisualEffectType(for: mode)
    }
    
    // SlideDialConfig / RotationDialConfig
    switch config.cropViewConfig.builtInRotationControlViewType {
    case .slideDial(var slideConfig):
        applySlideDialAppearance(to: &slideConfig, for: mode)
        config.cropViewConfig.builtInRotationControlViewType = .slideDial(config: slideConfig)
    case .rotationDial(var dialConfig):
        dialConfig.theme = AppearanceColorPreset.rotationDialTheme(for: mode)
        config.cropViewConfig.builtInRotationControlViewType = .rotationDial(config: dialConfig)
    }
}

private func applySlideDialAppearance(to config: inout SlideDialConfig, for mode: AppearanceMode) {
    config.scaleColor = AppearanceColorPreset.slideDialScaleColor(for: mode)
    config.majorScaleColor = AppearanceColorPreset.slideDialMajorScaleColor(for: mode)
    config.inactiveColor = AppearanceColorPreset.slideDialInactiveColor(for: mode)
    config.ringColor = AppearanceColorPreset.slideDialRingColor(for: mode)
    config.buttonFillColor = AppearanceColorPreset.slideDialButtonFillColor(for: mode)
    config.iconColor = AppearanceColorPreset.slideDialIconColor(for: mode)
    config.centralDotColor = AppearanceColorPreset.slideDialCentralDotColor(for: mode)
}

private func buildCropView(withImage image: UIImage,
                           config cropViewConfig: CropViewConfig,
                           rotationControlView: RotationControlViewProtocol?) -> CropViewProtocol {
    let cropAuxiliaryIndicatorView = CropAuxiliaryIndicatorView(frame: .zero,
                                                                config: cropViewConfig.cropAuxiliaryIndicatorConfig)
    let displayImage = image.downsampledIfNeeded(maxPixelCount: cropViewConfig.maxImagePixelCount)
    let imageContainer = ImageContainer(image: displayImage)
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
        dimmingView.overLayerFillColor = color
        visualEffectView.overLayerFillColor = color
    } else {
        let overlayColor = AppearanceColorPreset.dimmingOverlayColor(for: cropViewConfig.appearanceMode)
        dimmingView.overLayerFillColor = overlayColor
        visualEffectView.overLayerFillColor = overlayColor
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
            // When rotation type selector is enabled, default to slideDial for Apple Photos-like UX
            let controlViewType: CropViewConfig.BuiltInRotationControlViewType
            if cropViewConfig.enablePerspectiveCorrection {
                switch cropViewConfig.builtInRotationControlViewType {
                case .rotationDial:
                    controlViewType = .slideDial()
                case .slideDial:
                    controlViewType = cropViewConfig.builtInRotationControlViewType
                }
            } else {
                controlViewType = cropViewConfig.builtInRotationControlViewType
            }
            
            switch controlViewType {
            case .rotationDial(let config):
                let viewModel = RotationDialViewModel()
                let dialPlate = RotationDialPlate(frame: .zero, config: config)
                cropView.rotationControlView = RotationDial(frame: .zero,
                                                            config: config,
                                                            viewModel: viewModel,
                                                            dialPlate: dialPlate)
            case .slideDial(var config):
                // When rotation type selector is enabled, use the withTypeSelector mode
                if cropViewConfig.enablePerspectiveCorrection {
                    config.mode = .withTypeSelector
                }
                // Apply appearance colors if not already applied
                // (e.g. when auto-switching from rotationDial to slideDial)
                let mode = cropViewConfig.appearanceMode
                if mode != .forceDark {
                    applySlideDialAppearance(to: &config, for: mode)
                }
                let viewModel = SlideDialViewModel()
                let slideRuler = SlideRuler(frame: .zero, config: config)
                let slideDial = SlideDial(frame: .zero,
                                          config: config,
                                          viewModel: viewModel,
                                          slideRuler: slideRuler)
                cropView.rotationControlView = slideDial
            }
        }
    }
}
