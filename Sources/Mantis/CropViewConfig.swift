import UIKit

public struct CropViewConfig {
    /**
        This value is for how easy to drag crop box. The bigger, the easier.
     */
    public var cropBoxHotAreaUnit: CGFloat = 32 {
        didSet {
            assert(cropBoxHotAreaUnit > 0)
        }
    }
    
    public var cropShapeType: CropShapeType = .rect
    
    public var cropBorderWidth: CGFloat = 0 {
        didSet {
            assert(cropBorderWidth > 0)
        }
    }
    
    public var cropBorderColor: UIColor = .clear
    
    public var cropMaskVisualEffectType: CropMaskVisualEffectType = .blurDark
    
    public var presetTransformationType: PresetTransformationType = .none
    
    public var minimumZoomScale: CGFloat = 1 {
        didSet {
            assert(minimumZoomScale >= 1)
        }
    }
    
    public var maximumZoomScale: CGFloat = 15
    
    /**
     Rotation Dial currently is tightly coupled with other parts of CropView, we see rotation dial as a part of CropView,
     so we put dialConfig inside CropViewConfig
     */
    public var dialConfig = DialConfig()
    
    public var showRotationDial = true
    
    public var padding: CGFloat = 14 {
        didSet {
            assert(padding >= 3, "padding is need to be at least 3 in order to show the whole crop box handles")
        }
    }
    
    var minimumCropBoxSize: CGFloat = 42

    public init() {}
}
