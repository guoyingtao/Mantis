import UIKit

public struct CropViewConfig {
    /**
        This value is for how easy to drag crop box. The bigger, the easier.
     */
    @available(*, deprecated, message: "Use cropAuxiliaryIndicatorStyle.cropBoxHotAreaUnit instead")
    public var cropBoxHotAreaUnit: CGFloat {
        get {
            cropAuxiliaryIndicatorConfig.cropBoxHotAreaUnit
        }
        set {
            cropAuxiliaryIndicatorConfig.cropBoxHotAreaUnit = newValue
        }
    }
    
    @available(*, deprecated, message: "Use cropAuxiliaryIndicatorStyle.disableCropBoxDeformation instead")
    public var disableCropBoxDeformation: Bool {
        get {
            cropAuxiliaryIndicatorConfig.disableCropBoxDeformation
        }
        set {
            cropAuxiliaryIndicatorConfig.disableCropBoxDeformation = newValue
        }
    }
    
    @available(*, deprecated, message: "Use cropAuxiliaryIndicatorConfig.style instead")
    public var cropAuxiliaryIndicatorStyle: CropAuxiliaryIndicatorStyleType {
        get {
            cropAuxiliaryIndicatorConfig.style
        }
        set {
            cropAuxiliaryIndicatorConfig.style = newValue
        }
    }
    
    public var cropAuxiliaryIndicatorConfig = CropAuxiliaryIndicatorConfig()
    
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
    
    public var rotateCropBoxFor90DegreeRotation = true
    
    public var minimumCropBoxSize: CGFloat = 42 {
        didSet {
            assert(minimumCropBoxSize >= 4)
        }
    }
    
    public enum BuiltInRotationControlViewType {
        case rotationDial(config: RotationDialConfig = .init())
        case slideDial(config: SlideDialConfig = .init())
    }
    
    public var builtInRotationControlViewType: BuiltInRotationControlViewType = .rotationDial()
    
    public var keyboardZoomScaleFactor: CGFloat = 1.1
    
    public init() {}
}
