//
//  CropToolbarConfig.swift
//  Mantis
//
//  Created by yingtguo on 7/19/22.
//

import UIKit

public struct CropToolbarConfig {
    public var heightForVerticalOrientation: CGFloat = 44 {
        didSet {
            assert(heightForVerticalOrientation >= 44)
        }
    }
    
    public var widthForHorizontalOrientation: CGFloat = 80 {
        didSet {
            assert(widthForHorizontalOrientation >= 44)
        }
    }

    /**
     The color settings are not for Mac Catalyst (Optimize Interface for Mac) for now
     I haven't figured out a correct way to set button title color for this scenario
     */
    public var backgroundColor: UIColor = .black
    public var foregroundColor: UIColor = .white

    public var toolbarButtonOptions: ToolbarButtonOptions = .default
    
    // The properties below are required by CropViewController and for some specific scenarios
    // Most of time you can set just their default values as CropToolbarConfig does

    /**
     - .presentRatioListFromButton shows ratio list after tapping a button
     - .alwaysShowRatioList shows ratio list without tapping any button
     */
    public var ratioCandidatesShowType: RatioCandidatesShowType = .presentRatioListFromButton
    
    /**
     .adaptive will show vertical / horizontal or horizontal / vertical size
     based on the device orientations.
     */
    public var fixedRatiosShowType: FixedRatiosShowType = .adaptive
    
    /**
     When Config.presetFixedRatioType is canUseMultiplePresetFixedRatio and default ratio is not 0,
     this property will be set to true.
     */
    public var presetRatiosButtonSelected = false
    
    /**
     When Config.presetFixedRatioType is alwaysUsingOnePresetFixedRatio,
     this property will be set to false.
     Then the FixedRatioSettingButton should not show up.
     */
    public var includeFixedRatiosSettingButton = true
    
    /**
     - For .normal, the CropToolBar has cancel and crop buttons
     - For .embedded, the CropToolBar does not have cancel and crop buttons
     When embeding CropViewController to another UIViewController, that UIViewController should be
     in charge of cancel and crop buttons
     */
    public var mode: CropToolbarMode = .normal
    
    public init() {}
}
