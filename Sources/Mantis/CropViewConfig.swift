import UIKit

public struct CropViewConfig {
    /**
        This value is for how easy to drag crop box. The bigger, the easier.
     */
    public var cropBoxHotAreaUnit: CGFloat = 32
    
    public var cropShapeType: CropShapeType = .rect
    
    public var cropBorderWidth: CGFloat = 0
    
    public var cropBorderColor: UIColor = .clear
    
    public var cropMaskVisualEffectType: CropMaskVisualEffectType = .blurDark
    
    public var presetTransformationType: PresetTransformationType = .none
    
    /// minimumZoomScale must be no less than 1
    public var minimumZoomScale: CGFloat = 1
    
    public var maximumZoomScale: CGFloat = 15
    
    /**
     Rotation Dial currently is tightly coupled with other parts of CropView, we see rotation dial as a part of CropView,
     so we put dialConfig inside CropViewConfig
     */
    public var dialConfig = DialConfig()
    
    public var showRotationDial = true
    
    public var padding: CGFloat = 14
    
    var minimumCropBoxSize: CGFloat = 42

    public init() {}
}
