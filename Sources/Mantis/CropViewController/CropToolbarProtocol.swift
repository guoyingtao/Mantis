//
//  CropToolbarProtocol.swift
//  Mantis
//
//  Created by Echo on 4/25/20.
//

import UIKit

/**
    Inside Mantis, CropViewController implements all delegate methods 
 */
public protocol CropToolbarDelegate: AnyObject {
    func didSelectCancel()
    func didSelectCrop()
    func didSelectCounterClockwiseRotate()
    func didSelectClockwiseRotate()
    func didSelectReset()
    func didSelectSetRatio()
    func didSelectRatio(ratio: Double)
    func didSelectAlterCropper90Degree()
    func didSelectHorizontallyFlip()
    func didSelectVerticallyFlip()
}

public protocol CropToolbarIconProvider: AnyObject {
    func getClockwiseRotationIcon() -> UIImage?
    func getCounterClockwiseRotationIcon() -> UIImage?
    func getResetIcon() -> UIImage?
    func getSetRatioIcon() -> UIImage?
    func getAlterCropper90DegreeIcon() -> UIImage?
    func getCancelIcon() -> UIImage?
    func getCropIcon() -> UIImage?
    func getHorizontallyFlipIcon() -> UIImage?
    func getVerticallyFlipIcon() -> UIImage?
}

public extension CropToolbarIconProvider {
    func getClockwiseRotationIcon() -> UIImage? { return nil }
    func getCounterClockwiseRotationIcon() -> UIImage? { return nil }
    func getResetIcon() -> UIImage? { return nil }
    func getSetRatioIcon() -> UIImage? { return nil }
    func getAlterCropper90DegreeIcon() -> UIImage? { return nil }
    func getCancelIcon() -> UIImage? { return nil }
    func getCropIcon() -> UIImage? { return nil }
    func getHorizontallyFlipIcon() -> UIImage? { return nil }
    func getVerticallyFlipIcon() -> UIImage? { return nil }
}

public protocol CropToolbarProtocol: UIView {
    var config: CropToolbarConfigProtocol? { get }
    
    var cropToolbarDelegate: CropToolbarDelegate? { get set }
    
    var iconProvider: CropToolbarIconProvider? { get set }

    func createToolbarUI(config: CropToolbarConfigProtocol?)
    func handleFixedRatioSetted(ratio: Double)
    func handleFixedRatioUnSetted()
    
    // MARK: - The following functions have default implementations
    func getRatioListPresentSourceView() -> UIView?
    
    func respondToOrientationChange()
    func adjustLayoutWhenOrientationChange()
        
    func handleCropViewDidBecomeResettable()
    func handleCropViewDidBecomeUnResettable()
}

public extension CropToolbarProtocol {
    func getRatioListPresentSourceView() -> UIView? {
        return nil
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
