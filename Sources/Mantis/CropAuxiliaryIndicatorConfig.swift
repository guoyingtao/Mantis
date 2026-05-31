//
//  CropAuxiliaryIndicatorConfig.swift
//  Mantis
//
//  Created by Yingtao Guo on 7/19/24.
//

import UIKit

public struct CropAuxiliaryIndicatorConfig {
    /**
        This value is for how easy to drag crop box. The bigger, the easier.
     */
    public var cropBoxHotAreaUnit: CGFloat = 32 {
        didSet {
            assert(cropBoxHotAreaUnit > 0)
        }
    }
    
    public var disableCropBoxDeformation = false
    public var style: CropAuxiliaryIndicatorStyleType = .normal
    
    /// When `nil`, the value is resolved from the active `AppearanceMode` (or
    /// falls back to white). Set explicitly to override the appearance preset.
    public var borderNormalColor: UIColor?

    /// The color of the border when showing which border is touched currently.
    /// `nil` defers to the appearance preset; see `borderNormalColor`.
    public var borderHintColor: UIColor?

    /// `nil` defers to the appearance preset; see `borderNormalColor`.
    public var cornerHandleColor: UIColor?

    /// `nil` defers to the appearance preset; see `borderNormalColor`.
    public var edgeLineHandleColor: UIColor?
    
    public var gridMainColor = UIColor.white
    
    /**
        This property is only used when rotating the image
     */
    public var gridSecondaryColor = UIColor.lightGray
    
    public init() {}
}
