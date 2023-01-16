//
//  Mantis.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
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

var localizationConfig = LocalizationConfig()

private(set) var bundle: Bundle? = {
    return Mantis.Config.bundle
}()

// MARK: - APIs
public func cropViewController(image: UIImage,
                               config: Mantis.Config = Mantis.Config(),
                               cropToolbar: CropToolbarProtocol = CropToolbar(frame: .zero)) -> CropViewController {
    let cropViewController = CropViewController(config: config)
    setupCropView(for: cropViewController, with: image, and: config.cropViewConfig)
    setupCropToolbar(for: cropViewController, with: cropToolbar)
    return cropViewController
}

public func setupCropView(for cropViewController: CropViewController, with image: UIImage, and cropViewConfig: CropViewConfig) {
    let cropView = CropView(image: image, cropViewConfig: cropViewConfig)
    cropViewController.cropView = cropView
}

public func setupCropToolbar(for cropViewController: CropViewController, with cropToolbar: CropToolbarProtocol? = nil) {
    cropViewController.cropToolbar = cropToolbar ?? CropToolbar(frame: .zero)
}

public func setupCropViewController(_ cropViewController: CropViewController, with image: UIImage?, and config: Mantis.Config) {
    cropViewController.config = config
    
    if let image = image {
        setupCropView(for: cropViewController, with: image, and: config.cropViewConfig)
    }
    
    setupCropToolbar(for: cropViewController)
}

public func locateResourceBundle(by hostClass: AnyClass) {
    LocalizedHelper.setBundle(Bundle(for: hostClass))
}

public func crop(image: UIImage, by cropInfo: CropInfo) -> UIImage? {
    return image.crop(by: cropInfo)
}
