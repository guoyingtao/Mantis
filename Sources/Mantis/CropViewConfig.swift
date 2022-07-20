import UIKit

public struct CropViewConfig {
    /**
        This value is for how easy to drag crop box. The bigger, the easier.
     */
    public var cropBoxHotAreaUnit: CGFloat = 32
    
    public var cropShapeType: CropShapeType = .rect
    
    public var cropMaskVisualEffectType: CropMaskVisualEffectType = .blurDark
    
    public var presetTransformationType: PresetTransformationType = .none
    
    public var minimumZoomScale: CGFloat = 1
    
    public var maximumZoomScale: CGFloat = 15
    
    /**
     Rotation Dial currently is tightly coupled with other parts of CropView, we see rotation dial as a part of CropView,
     so we put dialConfig inside CropViewConfig
     */
    public var dialConfig: DialConfig? = DialConfig()
    
    var minimumBoxSize: CGFloat = 42
    
    var padding: CGFloat = 14

    public init() {}
}
