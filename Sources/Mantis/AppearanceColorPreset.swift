//
//  AppearanceColorPreset.swift
//  Mantis
//
//  Created by Echo on 2/22/26.
//

import UIKit

enum AppearanceColorPreset {
    
    private static let lightBackground = UIColor(white: 0.95, alpha: 1.0)
    
    /// Creates a dynamic color that adapts to dark/light mode.
    /// Falls back to the dark color on iOS 12.
    private static func dynamicColor(dark: UIColor, light: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
        } else {
            return dark
        }
    }
    
    // MARK: - Main Background (CropViewController / CropView)
    static func mainBackground(for mode: AppearanceMode) -> UIColor {
        switch mode {
        case .forceDark:
            return .black
        case .forceLight:
            return lightBackground
        case .system:
            return dynamicColor(dark: .black, light: lightBackground)
        }
    }
    
    // MARK: - CropToolbarConfig
    static func toolbarBackground(for mode: AppearanceMode) -> UIColor {
        switch mode {
        case .forceDark:
            return .black
        case .forceLight:
            return lightBackground
        case .system:
            return dynamicColor(dark: .black, light: lightBackground)
        }
    }
    
    static func toolbarForeground(for mode: AppearanceMode) -> UIColor {
        let lightForeground = UIColor(white: 0.1, alpha: 1.0)
        switch mode {
        case .forceDark:
            return .white
        case .forceLight:
            return lightForeground
        case .system:
            return dynamicColor(dark: .white, light: lightForeground)
        }
    }
    
    // MARK: - Dimming & Mask
    static func dimmingOverlayColor(for mode: AppearanceMode) -> UIColor {
        let lightOverlay = UIColor(white: 0.92, alpha: 1.0)
        switch mode {
        case .forceDark:
            return .black
        case .forceLight:
            return lightOverlay
        case .system:
            return dynamicColor(dark: .black, light: lightOverlay)
        }
    }
    
    static func maskVisualEffectType(for mode: AppearanceMode) -> CropMaskVisualEffectType {
        switch mode {
        case .forceDark:
            return .blurDark
        case .forceLight:
            return .light
        case .system:
            return .blurSystem
        }
    }
    
    // MARK: - SlideDialConfig
    static func slideDialScaleColor(for mode: AppearanceMode) -> UIColor {
        let lightScale = UIColor(white: 0.78, alpha: 1.0)
        switch mode {
        case .forceDark:
            return .gray
        case .forceLight:
            return lightScale
        case .system:
            return dynamicColor(dark: .gray, light: lightScale)
        }
    }
    
    static func slideDialMajorScaleColor(for mode: AppearanceMode) -> UIColor {
        let lightMajor = UIColor(white: 0.55, alpha: 1.0)
        switch mode {
        case .forceDark:
            return .white
        case .forceLight:
            return lightMajor
        case .system:
            return dynamicColor(dark: .white, light: lightMajor)
        }
    }
    
    static func slideDialInactiveColor(for mode: AppearanceMode) -> UIColor {
        let lightInactive = UIColor(white: 0.15, alpha: 1.0)
        switch mode {
        case .forceDark:
            return .white
        case .forceLight:
            return lightInactive
        case .system:
            return dynamicColor(dark: .white, light: lightInactive)
        }
    }
    
    static func slideDialRingColor(for mode: AppearanceMode) -> UIColor {
        let darkRing = UIColor(white: 0.45, alpha: 1.0)
        let lightRing = UIColor(white: 0.82, alpha: 1.0)
        switch mode {
        case .forceDark:
            return darkRing
        case .forceLight:
            return lightRing
        case .system:
            return dynamicColor(dark: darkRing, light: lightRing)
        }
    }
    
    static func slideDialButtonFillColor(for mode: AppearanceMode) -> UIColor {
        let darkFill = UIColor(white: 0.2, alpha: 1.0)
        let lightFill = UIColor.white
        switch mode {
        case .forceDark:
            return darkFill
        case .forceLight:
            return lightFill
        case .system:
            return dynamicColor(dark: darkFill, light: lightFill)
        }
    }
    
    static func slideDialIconColor(for mode: AppearanceMode) -> UIColor {
        let lightIcon = UIColor(white: 0.1, alpha: 1.0)
        switch mode {
        case .forceDark:
            return .white
        case .forceLight:
            return lightIcon
        case .system:
            return dynamicColor(dark: .white, light: lightIcon)
        }
    }
    
    static func slideDialCentralDotColor(for mode: AppearanceMode) -> UIColor {
        let lightDot = UIColor(white: 0.55, alpha: 1.0)
        switch mode {
        case .forceDark:
            return .white
        case .forceLight:
            return lightDot
        case .system:
            return dynamicColor(dark: .white, light: lightDot)
        }
    }
    
    // MARK: - RotationDialConfig
    static func rotationDialTheme(for mode: AppearanceMode) -> RotationDialConfig.Theme {
        switch mode {
        case .forceDark:
            return .dark
        case .forceLight:
            return .light
        case .system:
            return .dark
        }
    }
    
    // MARK: - RotationTypeSelector
    static func typeSelectorSelectedColor(for mode: AppearanceMode) -> UIColor {
        switch mode {
        case .forceDark:
            return .white
        case .forceLight:
            return .black
        case .system:
            return dynamicColor(dark: .white, light: .black)
        }
    }
    
    static func typeSelectorUnselectedColor(for mode: AppearanceMode) -> UIColor {
        let lightUnselected = UIColor(white: 0.55, alpha: 1.0)
        switch mode {
        case .forceDark:
            return .gray
        case .forceLight:
            return lightUnselected
        case .system:
            return dynamicColor(dark: .gray, light: lightUnselected)
        }
    }
    
    static func typeSelectorIndicatorColor(for mode: AppearanceMode) -> UIColor {
        switch mode {
        case .forceDark:
            return .white
        case .forceLight:
            return .black
        case .system:
            return dynamicColor(dark: .white, light: .black)
        }
    }
    
    // MARK: - RatioItemView
    static func ratioItemSelectedBackground(for mode: AppearanceMode) -> UIColor {
        let darkSelected = UIColor.lightGray.withAlphaComponent(0.7)
        let lightSelected = UIColor(white: 0.80, alpha: 1.0)
        switch mode {
        case .forceDark:
            return darkSelected
        case .forceLight:
            return lightSelected
        case .system:
            return dynamicColor(dark: darkSelected, light: lightSelected)
        }
    }
    
    static func ratioItemUnselectedBackground(for mode: AppearanceMode) -> UIColor {
        switch mode {
        case .forceDark:
            return .black
        case .forceLight:
            return lightBackground
        case .system:
            return dynamicColor(dark: .black, light: lightBackground)
        }
    }
    
    static func ratioItemSelectedText(for mode: AppearanceMode) -> UIColor {
        switch mode {
        case .forceDark:
            return .white
        case .forceLight:
            return .black
        case .system:
            return dynamicColor(dark: .white, light: .black)
        }
    }
    
    static func ratioItemUnselectedText(for mode: AppearanceMode) -> UIColor {
        let lightUnselected = UIColor(white: 0.4, alpha: 1.0)
        switch mode {
        case .forceDark:
            return .gray
        case .forceLight:
            return lightUnselected
        case .system:
            return dynamicColor(dark: .gray, light: lightUnselected)
        }
    }
    
    // MARK: - Auto-adjust button
    static func autoAdjustInactiveColor(for mode: AppearanceMode) -> UIColor {
        let lightInactive = UIColor(white: 0.55, alpha: 1.0)
        switch mode {
        case .forceDark:
            return .gray
        case .forceLight:
            return lightInactive
        case .system:
            return dynamicColor(dark: .gray, light: lightInactive)
        }
    }
    
    // MARK: - Activity Indicator
    static func activityIndicatorColor(for mode: AppearanceMode) -> UIColor {
        switch mode {
        case .forceDark:
            return .white
        case .forceLight:
            return .darkGray
        case .system:
            return dynamicColor(dark: .white, light: .darkGray)
        }
    }
}
