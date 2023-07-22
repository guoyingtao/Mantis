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
    
    /**
     When backgroundColor is set, cropMaskVisualEffectType is automatically set to custom type
     */
    public var backgroundColor: UIColor? {
        didSet {
            cropMaskVisualEffectType = .custom(color: backgroundColor!)
        }
    }
    
    public var cropMaskVisualEffectType: CropMaskVisualEffectType = .blurDark
    
    public var presetTransformationType: PresetTransformationType = .none
    
    public var minimumZoomScale: CGFloat = 1 {
        didSet {
            assert(minimumZoomScale >= 1)
        }
    }
    
    public var maximumZoomScale: CGFloat = 15
    
    @available(*, deprecated, message: "Use showAttachedRotationControlView instead")
    public var showRotationDial = true {
        didSet {
            showAttachedRotationControlView = showRotationDial
        }
    }
    
    public var showAttachedRotationControlView = true
    
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
    
    public enum BuiltInRotationControlViewType {
        case rotationDial(config: RotationDialConfig = .init())
        case slideDial(config: SlideDialConfig = .init())
    }
    
    public var builtInRotationControlViewType: BuiltInRotationControlViewType = .rotationDial()
    
    public init() {}
}
