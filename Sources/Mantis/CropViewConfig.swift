import UIKit

public struct CropViewConfig {
    public var cropViewMinimumBoxSize: CGFloat = 42
    public var padding: CGFloat = 14
    public var hotAreaUnit: CGFloat = 32
    public var cropShapeType: CropShapeType = .rect
    public var cropVisualEffectType: CropVisualEffectType = .blurDark
    public var minimumZoomScale: CGFloat = 1
    public var maximumZoomScale: CGFloat = 15
    
    /**
     Rotation Dial currently is tightly coupled with other parts of CropView, we see rotation dial as a part of CropView,
     so we put dialConfig inside CropViewConfig
     */
    public var dialConfig = DialConfig()
    public var showRotationDial = true

    public init() {}
}
