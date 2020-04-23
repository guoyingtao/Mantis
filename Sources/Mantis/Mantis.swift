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

private(set) var bundle: Bundle? = {
    return Mantis.Config.bundle
} ()

public func cropViewController(image: UIImage, config: Mantis.Config = Mantis.Config()) -> CropViewController {
    return CropViewController(image: image, config: config, mode: .normal)
}

public func cropCustomizableViewController(image: UIImage, config: Mantis.Config = Mantis.Config()) -> CropViewController {
    return CropViewController(image: image, config: config, mode: .customizable)
}

public func getCroppedImage(byCropInfo info: CropInfo, andImage image: UIImage) -> UIImage? {
    return image.getCroppedImage(byCropInfo: info)
}

public typealias Transformation = (
    offset: CGPoint,
    rotation: CGFloat,
    scale: CGFloat,
    manualZoomed: Bool,
    maskFrame: CGRect
)

public typealias CropInfo = (translation: CGPoint, rotation: CGFloat, scale: CGFloat, cropSize: CGSize, imageViewSize: CGSize)

public enum PresetTransformationType {
    case none
    case presetInfo(info: Transformation)
}

public enum PresetFixedRatioType {
    /** When choose alwaysUsingOnePresetFixedRatio, fixed-ratio setting button does not show.
     */
    case alwaysUsingOnePresetFixedRatio(ratio: Double)
    case canUseMultiplePresetFixedRatio
}

public enum CropShapeType {
    case rect
    
    /**
     When maskOnly is true, the cropped image is kept rect
     */
    case ellipse(maskOnly: Bool = false)

    /**
     When maskOnly is true, the cropped image is kept rect
     */
    case roundedRect(radiusToShortSide: CGFloat, maskOnly: Bool = false)
}

public struct Config {
    public var presetTransformationType: PresetTransformationType = .none
    public var cropShapeType: CropShapeType = .rect
    public var ratioOptions: RatioOptions = .all
    public var presetFixedRatioType: PresetFixedRatioType = .canUseMultiplePresetFixedRatio
    public var showRotationDial = true
    public var showToolbar = true
    public var optionButtonFontSize: CGFloat = 14
    public var optionButtonFontSizeForPad: CGFloat = 20
    
    var customRatios: [(width: Int, height: Int)] = []
    
    static private var bundleIdentifier: String = {
        return "com.echo.framework.Mantis"
    } ()
    
    static private(set) var bundle: Bundle? = {
        guard let bundle = Bundle(identifier: bundleIdentifier) else {
            return nil
        }
        
        if let url = bundle.url(forResource: "Resource", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return bundle
        }
        return nil
    } ()
    
    public init() {
    }
        
    mutating public func addCustomRatio(byHorizontalWidth width: Int, andHorizontalHeight height: Int) {
        customRatios.append((width, height))
    }

    mutating public func addCustomRatio(byVerticalWidth width: Int, andVerticalHeight height: Int) {
        customRatios.append((height, width))
    }
    
    func hasCustomRatios() -> Bool {
        return customRatios.count > 0
    }
    
    func getCustomRatioItems() -> [RatioItemType] {
        return customRatios.map {
            (String("\($0.width):\($0.height)"), Double($0.width)/Double($0.height), String("\($0.height):\($0.width)"), Double($0.height)/Double($0.width))
        }
    }
}

