//
//  CropToolbarProtocol.swift
//  Mantis
//
//  Created by Echo on 4/25/20.
//

import UIKit

public protocol CropToolbarDelegate: AnyObject {
    func didSelectCancel()
    func didSelectCrop()
    func didSelectCounterClockwiseRotate()
    func didSelectClockwiseRotate()
    func didSelectReset()
    func didSelectSetRatio()
    func didSelectRatio(ratio: Double)
    func didSelectAlterCropper90Degree()
}

public protocol CropToolbarIconProvider: AnyObject {
    func getClockwiseRotationIcon() -> UIImage?
    func getCounterClockwiseRotationIcon() -> UIImage?
    func getResetIcon() -> UIImage?
    func getSetRatioIcon() -> UIImage?
    func getAlterCropper90DegreeIcon() -> UIImage?
}

public extension CropToolbarIconProvider {
    func getClockwiseRotationIcon() -> UIImage? { return nil }
    func getCounterClockwiseRotationIcon() -> UIImage? { return nil }
    func getResetIcon() -> UIImage? { return nil }
    func getSetRatioIcon() -> UIImage? { return nil }
    func getAlterCropper90DegreeIcon() -> UIImage? { return nil }
}

public protocol CropToolbarProtocol: UIView {
    var heightForVerticalOrientation: CGFloat? { get set }
    var widthForHorizonOrientation: CGFloat? { get set }

    var cropToolbarDelegate: CropToolbarDelegate? { get set }
    
    var iconProvider: CropToolbarIconProvider? { get set }

    func createToolbarUI(config: CropToolbarConfig)
    func handleFixedRatioSetted(ratio: Double)
    func handleFixedRatioUnSetted()
    
    // MARK: - The following functions have default implementations
    func getRatioListPresentSourceView() -> UIView?
    
    func initSizeConstraints(heightForVerticalOrientation: CGFloat,
                             widthForHorizonOrientation: CGFloat)
    
    func respondToOrientationChange()
    func adjustLayoutWhenOrientationChange()
        
    func handleCropViewDidBecomeResettable()
    func handleCropViewDidBecomeUnResettable()
}

public extension CropToolbarProtocol {
    func getRatioListPresentSourceView() -> UIView? {
        return nil
    }
    
    func initSizeConstraints(heightForVerticalOrientation: CGFloat, widthForHorizonOrientation: CGFloat) {
        self.heightForVerticalOrientation = heightForVerticalOrientation
        self.widthForHorizonOrientation = widthForHorizonOrientation
        respondToOrientationChange()
    }
    
    private func adjustIntrinsicContentSize() {
        invalidateIntrinsicContentSize()
        
        let highPriority: Float = 10000
        let lowPriority: Float = 1

        if Orientation.isPortrait {
            setContentHuggingPriority(UILayoutPriority(highPriority), for: .vertical)
            setContentCompressionResistancePriority(UILayoutPriority(highPriority), for: .vertical)
            setContentHuggingPriority(UILayoutPriority(lowPriority), for: .horizontal)
            setContentCompressionResistancePriority(UILayoutPriority(lowPriority), for: .horizontal)
        } else {
            setContentHuggingPriority(UILayoutPriority(highPriority), for: .horizontal)
            setContentCompressionResistancePriority(UILayoutPriority(highPriority), for: .horizontal)
            setContentHuggingPriority(UILayoutPriority(lowPriority), for: .vertical)
            setContentCompressionResistancePriority(UILayoutPriority(lowPriority), for: .vertical)
        }
    }
    
    func respondToOrientationChange() {
        adjustIntrinsicContentSize()
        adjustLayoutWhenOrientationChange()
    }
    
    func adjustLayoutWhenOrientationChange() {}
    
    func handleCropViewDidBecomeResettable() {}
    
    func handleCropViewDidBecomeUnResettable() {}
}
