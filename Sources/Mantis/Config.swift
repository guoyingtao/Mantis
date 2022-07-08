//
//  Config.swift
//  Mantis
//
//  Created by Echo on 07/07/22.
//  Copyright © 2022 Echo. All rights reserved.
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
    
    public var backgroundColor: UIColor = .black
    public var foregroundColor: UIColor = .white

    var mode: CropToolbarMode = .normal
    var includeFixedRatioSettingButton = true
    
    public init() {}
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
