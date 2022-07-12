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

public protocol CropToolbarConfigProtocol {
    var heightForVerticalOrientation: CGFloat { get set }
    var widthForHorizontalOrientation: CGFloat { get set }

    var backgroundColor: UIColor { get set }
    var foregroundColor: UIColor { get set }
    
    var optionButtonFontSize: CGFloat { get set }
    var optionButtonFontSizeForPad: CGFloat { get set }
    
    var toolbarButtonOptions: ToolbarButtonOptions { get set }
    
    // The properties below are required by CropViewController and for some specific scenarios
    // Most of time you can set just their default values as CropToolbarConfig does
    
    /**
     - .presentRatioListFromButton shows ratio list after tapping a button
     - .alwaysShowRatioList shows ratio list without tapping any button
     */
    var ratioCandidatesShowType: RatioCandidatesShowType { get set }
    
    /**
     .adaptive will show vertical / horizontal or horizontal / vertical size
     based on the device orientations.
     */
    var fixedRatiosShowType: FixedRatiosShowType { get set }
    
    /**
     When Config.presetFixedRatioType is canUseMultiplePresetFixedRatio and default ratio is not 0,
     this property will be set to true.
     */
    var presetRatiosButtonSelected: Bool { get set }
    
    /**
     When Config.presetFixedRatioType is alwaysUsingOnePresetFixedRatio,
     this property will be set to false.
     Then the FixedRatioSettingButton should not show up.
     */
    var includeFixedRatiosSettingButton: Bool { get set }
    
    /**
     - For .normal, the CropToolBar has cancel and crop buttons
     - For .simple, the CropToolBar does not have cancel and crop buttons
     When embeding CropViewController to another UIViewController, that UIViewController should be
     in charge of cancel and crop buttons
     */
    var mode: CropToolbarMode { get set }
}

// MARK: - CropToolbarConfig
public struct CropToolbarConfig: CropToolbarConfigProtocol {
    public var heightForVerticalOrientation: CGFloat = 44
    public var widthForHorizontalOrientation: CGFloat = 80

    public var optionButtonFontSize: CGFloat = 14
    public var optionButtonFontSizeForPad: CGFloat = 20

    /**
     The color settings are not for Mac Catalyst (Optimize Interface for Mac) for now
     I haven't figured out a correct way to set button title color for this scenario
     */
    public var backgroundColor: UIColor = .black
    public var foregroundColor: UIColor = .white

    public var toolbarButtonOptions: ToolbarButtonOptions = .default
    public var ratioCandidatesShowType: RatioCandidatesShowType = .presentRatioListFromButton
    public var fixedRatiosShowType: FixedRatiosShowType = .adaptive
    public var presetRatiosButtonSelected = false
    public var includeFixedRatiosSettingButton = true
    public var mode: CropToolbarMode = .normal
    
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
    public var cropToolbarConfig: CropToolbarConfigProtocol = CropToolbarConfig()
    public private(set) var localizationConfig = Mantis.localizationConfig
    public var showAttachedCropToolbar = true

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
            (String("\($0.width):\($0.height)"), Double($0.width)/Double($0.height),
             String("\($0.height):\($0.width)"), Double($0.height)/Double($0.width))
        }
    }
}
