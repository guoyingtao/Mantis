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
}()

internal var localizationConfig = LocalizationConfig()

// MARK: - APIs
public func cropViewController(image: UIImage,
                               config: Mantis.Config = Mantis.Config(),
                               cropToolbar: CropToolbarProtocol = CropToolbar(frame: CGRect.zero)) -> CropViewController {
    return CropViewController(image: image,
                              config: config,
                              mode: .normal,
                              cropToolbar: cropToolbar)
}

public func cropCustomizableViewController(image: UIImage,
                                           config: Mantis.Config = Mantis.Config(),
                                           cropToolbar: CropToolbarProtocol = CropToolbar(frame: CGRect.zero)) -> CropViewController {
    return CropViewController(image: image,
                              config: config,
                              mode: .customizable,
                              cropToolbar: cropToolbar)
}

public func locateResourceBundle(by hostClass: AnyClass) {
    LocalizedHelper.setBundle(Bundle(for: hostClass))
}

@available(*, deprecated, renamed: "crop(image:by:)")
public func getCroppedImage(byCropInfo cropInfo: CropInfo, andImage image: UIImage) -> UIImage? {
    return image.crop(by: cropInfo)
}

public func crop(image: UIImage, by cropInfo: CropInfo) -> UIImage? {
    return image.crop(by: cropInfo)
}

// MARK: - Type Aliases
public typealias Transformation = (
    offset: CGPoint,
    rotation: CGFloat,
    scale: CGFloat,
    manualZoomed: Bool,
    intialMaskFrame: CGRect,
    maskFrame: CGRect,
    scrollBounds: CGRect
)

public typealias CropInfo = (translation: CGPoint, rotation: CGFloat, scale: CGFloat, cropSize: CGSize, imageViewSize: CGSize)

// MARK: - Enums
public enum PresetTransformationType {
    case none
    case presetInfo(info: Transformation)
    case presetNormalizedInfo(normailizedInfo: CGRect)
}

public enum PresetFixedRatioType {
    /** When choose alwaysUsingOnePresetFixedRatio, fixed-ratio setting button does not show.
     */
    case alwaysUsingOnePresetFixedRatio(ratio: Double = 0)
    case canUseMultiplePresetFixedRatio(defaultRatio: Double = 0)
}

public enum CropVisualEffectType {
    case blurDark
    case dark
    case light
    case none
}

public enum CropShapeType {
    case rect

    /**
      The ratio of the crop mask will always be 1:1.
     ### Notice
     It equals cropShapeType = .rect
     and presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
     */
    case square

    /**
     When maskOnly is true, the cropped image is kept rect
     */
    case ellipse(maskOnly: Bool = false)

    /**
      The ratio of the crop mask will always be 1:1 and when maskOnly is true, the cropped image is kept rect.
     ### Notice
     It equals cropShapeType = .ellipse and presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
     */
    case circle(maskOnly: Bool = false)

    /**
     When maskOnly is true, the cropped image is kept rect
     */
    case roundedRect(radiusToShortSide: CGFloat, maskOnly: Bool = false)

    case diamond(maskOnly: Bool = false)

    case heart(maskOnly: Bool = false)

    case polygon(sides: Int, offset: CGFloat = 0, maskOnly: Bool = false)

    /**
      Each point should have normailzed values whose range is 0...1
     */
    case path(points: [CGPoint], maskOnly: Bool = false)
}

public enum RatioCandidatesShowType {
    case presentRatioList
    case alwaysShowRatioList
}

public enum FixRatiosShowType {
    case adaptive
    case horizontal
    case vetical
}

// MARK: - Localization
public class LocalizationConfig {
    public var bundle: Bundle? = Mantis.Config.bundle
    public var tableName = "MantisLocalizable"
}

// MARK: - CropToolbarConfig
public struct CropToolbarConfig {
    public var optionButtonFontSize: CGFloat = 14
    public var optionButtonFontSizeForPad: CGFloat = 20
    public var cropToolbarHeightForVertialOrientation: CGFloat = 44
    public var cropToolbarWidthForHorizontalOrientation: CGFloat = 80
    public var ratioCandidatesShowType: RatioCandidatesShowType = .presentRatioList
    public var fixRatiosShowType: FixRatiosShowType = .adaptive
    public var toolbarButtonOptions: ToolbarButtonOptions = .default
    public var presetRatiosButtonSelected = false

    var mode: CropToolbarMode = .normal
    var includeFixedRatioSettingButton = true
}

// MARK: - Config
public struct Config {
    public var presetTransformationType: PresetTransformationType = .none
    public var cropShapeType: CropShapeType = .rect
    public var cropVisualEffectType: CropVisualEffectType = .blurDark
    public var ratioOptions: RatioOptions = .all
    public var presetFixedRatioType: PresetFixedRatioType = .canUseMultiplePresetFixedRatio()
    public var showRotationDial = true
    public var dialConfig = DialConfig()
    public var cropToolbarConfig = CropToolbarConfig()
    public private(set) var localizationConfig = Mantis.localizationConfig

    var customRatios: [(width: Int, height: Int)] = []

    static private var bundleIdentifier: String = {
        return "com.echo.framework.Mantis"
    }()

    static private(set) var bundle: Bundle? = {
        guard let bundle = Bundle(identifier: bundleIdentifier) else {
            return nil
        }

        if let url = bundle.url(forResource: "MantisResources", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return bundle
        }
        return nil
    }()

    public init() {
    }

    mutating public func addCustomRatio(byHorizontalWidth width: Int, andHorizontalHeight height: Int) {
        customRatios.append((width, height))
    }

    mutating public func addCustomRatio(byVerticalWidth width: Int, andVerticalHeight height: Int) {
        customRatios.append((height, width))
    }

    func hasCustomRatios() -> Bool {
        return !customRatios.isEmpty
    }

    func getCustomRatioItems() -> [RatioItemType] {
        return customRatios.map {
            (String("\($0.width):\($0.height)"), Double($0.width)/Double($0.height), String("\($0.height):\($0.width)"), Double($0.height)/Double($0.width))
        }
    }
}
