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

import CoreImage
import UIKit

// MARK: - Face Validation
public struct FaceValidationConfig {
    public enum DetectorAccuracy {
        case low
        case high

        var ciAccuracy: String {
            switch self {
            case .low: return CIDetectorAccuracyLow
            case .high: return CIDetectorAccuracyHigh
            }
        }
    }

    /// When enabled, the cropped image is checked for faces before
    /// calling the crop-success delegate. If no face is found,
    /// `cropViewControllerDidFailFaceValidation(_:cropped:)` is called instead.
    public var enabled: Bool = false

    /// The accuracy used by `CIDetector`. Defaults to `.high`.
    public var detectorAccuracy: DetectorAccuracy = .high

    public init() {}
}

// MARK: - Localization
public final class LocalizationConfig {
    public var bundle: Bundle? = Mantis.Config.bundle
    public var tableName = "MantisLocalizable"
}
    
// MARK: - Config
public struct Config {
    
    public enum CropMode {
        case sync
        case async // We may need this mode when cropping big images
    }
        
    public var cropMode: CropMode = .sync
    
    /// Controls the appearance style of the crop UI.
    /// - `.forceDark`: Always dark (default, backward compatible)
    /// - `.forceLight`: Always light (similar to Apple Photos light mode)
    /// - `.system`: Follows system light/dark mode setting
    public var appearanceMode: AppearanceMode = .forceDark
    
    public var cropViewConfig = CropViewConfig()    
    public var cropToolbarConfig = CropToolbarConfig()
    
    public var ratioOptions: RatioOptions = .all
    public var presetFixedRatioType: PresetFixedRatioType = .canUseMultiplePresetFixedRatio()
    public var showAttachedCropToolbar = true
    
    public private(set) var localizationConfig = Mantis.localizationConfig
    
    var customRatios: [(width: Int, height: Int)] = []

    static private var bundleIdentifier: String = {
        return "com.echo.framework.Mantis"
    }()

    static private(set) var bundle: Bundle? = {
        guard let bundle = Bundle(identifier: bundleIdentifier) else {
            return nil
        }
        
        guard let url = bundle.url(forResource: "MantisResources", withExtension: "bundle") else {
            return nil
        }
        
        return Bundle(url: url)
    }()
    
    public var faceValidationConfig = FaceValidationConfig()

    public var enableUndoRedo: Bool = false
    
    static var language: Language?

    public init() {}

    mutating public func addCustomRatio(byHorizontalWidth width: Int, andHorizontalHeight height: Int) {
        assert(width > 0 && height > 0)
        customRatios.append((width, height))
    }

    mutating public func addCustomRatio(byVerticalWidth width: Int, andVerticalHeight height: Int) {
        assert(width > 0 && height > 0)
        customRatios.append((height, width))
    }

    var hasCustomRatios: Bool {
        return !customRatios.isEmpty
    }

    var customRatioItems: [RatioItemType?] {
        return customRatios.map {
            RatioItemType(nameH: String("\($0.width):\($0.height)"), ratioH: Double($0.width)/Double($0.height),
                          nameV: String("\($0.height):\($0.width)"), ratioV: Double($0.height)/Double($0.width))
        }
    }
}
