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
    func didSelectCancel(_ cropToolbar: CropToolbarProtocol?)
    func didSelectCrop(_ cropToolbar: CropToolbarProtocol?)
    func didSelectCounterClockwiseRotate(_ cropToolbar: CropToolbarProtocol?)
    func didSelectClockwiseRotate(_ cropToolbar: CropToolbarProtocol?)
    func didSelectReset(_ cropToolbar: CropToolbarProtocol?)
    func didSelectSetRatio(_ cropToolbar: CropToolbarProtocol?)
    func didSelectRatio(_ cropToolbar: CropToolbarProtocol?, ratio: Double)
    func didSelectFreeRatio(_ cropToolbar: CropToolbarProtocol?)
    func didSelectAlterCropper90Degree(_ cropToolbar: CropToolbarProtocol?)
    func didSelectHorizontallyFlip(_ cropToolbar: CropToolbarProtocol?)
    func didSelectVerticallyFlip(_ cropToolbar: CropToolbarProtocol?)
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
    var config: CropToolbarConfig { get set }
    var delegate: CropToolbarDelegate? { get set }
    var iconProvider: CropToolbarIconProvider? { get set }

    func createToolbarUI(config: CropToolbarConfig)
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
