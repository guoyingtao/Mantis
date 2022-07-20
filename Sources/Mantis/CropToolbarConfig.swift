//
//  CropToolbarConfig.swift
//  Mantis
//
//  Created by yingtguo on 7/19/22.
//

import UIKit

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
