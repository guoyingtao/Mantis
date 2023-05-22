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
     Rotation control view currently is tightly coupled with other parts of CropView, we see rotation control view as a part of CropView,
     so we put RotationControlViewConfig inside CropViewConfig
     */
    public var rotationControlViewConfig = RotationControlViewConfig()
    
    @available(*, deprecated, message: "Use showRotationControlView instead")
    public var showRotationDial = true {
        didSet {
            showRotationControlView = showRotationDial
        }
    }
    
    public var showRotationControlView = true
    
    public var padding: CGFloat = 14 {
        didSet {
            assert(padding >= 3, "padding is need to be at least 3 in order to show the whole crop box handles")
        }
    }
    
    public var cropActivityIndicator: ActivityIndicatorProtocol?
    
    public var cropActivityIndicatorSize = CGSize(width: 100, height: 100)
    
    public var rotationControlViewHeight: CGFloat = 60
    
    var minimumCropBoxSize: CGFloat = 42

    public var disableCropBoxDeformation = false
    
    public init() {}
}
