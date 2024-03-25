//
//  FakeCropView.swift
//  Mantis
//
//  Created by Yingtao Guo on 2/2/23.
//

import UIKit
@testable import Mantis

class FakeCropView: UIView, CropViewProtocol {
    func applyCropState(with cropState: Mantis.CropState) {
        
    }
    
    func makeCropState() -> Mantis.CropState {
        return CropState(
            rotationType: .none,
            degrees: 0.0,
            aspectRatioLockEnabled: false,
            aspectRato: 0.0,
            flipOddTimes: false,
            transformation: makeTransformation()
        )
    }
    
    var image = UIImage()
    
    var aspectRatioLockEnabled = false
    
    var delegate: CropViewDelegate?
    
    func initialSetup(delegate: CropViewDelegate, presetFixedRatioType: PresetFixedRatioType) {
    }
    
    func getRatioType(byImageIsOriginalHorizontal isHorizontal: Bool) -> RatioType {
        .horizontal
    }
    
    func getImageHorizontalToVerticalRatio() -> Double {
        0
    }
    
    func resetComponents() {
        
    }
    
    func prepareForViewWillTransition() {
        
    }
    
    func handleViewWillTransition() {
        
    }

    func setFixedRatio(_ ratio: Double, zoom: Bool, presetFixedRatioType: PresetFixedRatioType) {
        
    }
    
    func rotateBy90(withRotateType rotateType: RotateBy90DegreeType, completion: @escaping () -> Void) {
        
    }
    
    func handleAlterCropper90Degree() {
        
    }
    
    func setFreeCrop() {
        
    }
    
    func handlePresetFixedRatio(_ ratio: Double, transformation: Transformation) {
        
    }
    
    func transform(byTransformInfo transformation: Transformation, isUpdateRotationControlView: Bool) {
        
    }
    
    func getTransformInfo(byTransformInfo transformInfo: Transformation) -> Transformation {
        Transformation(offset: .zero, 
                       rotation: .zero,
                       scale: .zero,
                       isManuallyZoomed: false,
                       initialMaskFrame: .zero,
                       maskFrame: .zero,
                       cropWorkbenchViewBounds: .zero,
                       horizontallyFlipped: false,
                       verticallyFlipped: false)
    }
    
    func getTransformInfo(byNormalizedInfo normalizedInfo: CGRect) -> Transformation {
        Transformation(offset: .zero, 
                       rotation: .zero,
                       scale: .zero,
                       isManuallyZoomed: false,
                       initialMaskFrame: .zero,
                       maskFrame: .zero,
                       cropWorkbenchViewBounds: .zero,
                       horizontallyFlipped: false,
                       verticallyFlipped: false)
    }
    
    func processPresetTransformation(completion: (Transformation) -> Void) {
        
    }
    
    func horizontallyFlip() {
        
    }
    
    func verticallyFlip() {
        
    }
    
    func reset() {
        
    }
    
    func makeTransformation() -> Mantis.Transformation {
        return Transformation(offset: .zero, 
                              rotation: .zero,
                              scale: .zero,
                              isManuallyZoomed: false,
                              initialMaskFrame: .zero,
                              maskFrame: .zero,
                              cropWorkbenchViewBounds: .zero,
                              horizontallyFlipped: false,
                              verticallyFlipped: false)
    }
    
    func crop() -> CropOutput {
        CropOutput(nil,
                   Transformation(offset: .zero, 
                                  rotation: .zero,
                                  scale: .zero,
                                  isManuallyZoomed: false,
                                  initialMaskFrame: .zero,
                                  maskFrame: .zero,
                                  cropWorkbenchViewBounds: .zero,
                                  horizontallyFlipped: false,
                                  verticallyFlipped: false),
                   CropInfo(.zero, .zero, .zero, .zero, .zero, .zero,
                            CropRegion(topLeft: .zero,
                                       topRight: .zero,
                                       bottomLeft: .zero,
                                       bottomRight: .zero)))
    }
    
    func crop(_ image: UIImage) -> CropOutput {
        CropOutput(nil,
                   Transformation(offset: .zero, 
                                  rotation: .zero,
                                  scale: .zero,
                                  isManuallyZoomed: false,
                                  initialMaskFrame: .zero,
                                  maskFrame: .zero,
                                  cropWorkbenchViewBounds: .zero,
                                  horizontallyFlipped: false,
                                  verticallyFlipped: false),
                   CropInfo(.zero, .zero, .zero, .zero, .zero, .zero,
                            CropRegion(topLeft: .zero,
                                       topRight: .zero,
                                       bottomLeft: .zero,
                                       bottomRight: .zero)))
    }
    
    func asyncCrop(completion: @escaping (CropOutput) -> Void) {
        
    }
    
    func getCropInfo() -> CropInfo {
        CropInfo(.zero, .zero, .zero, .zero, .zero, .zero, CropRegion(topLeft: .zero, topRight: .zero, bottomLeft: .zero, bottomRight: .zero))
    }
    
    func getExpectedCropImageSize() -> CGSize {
        .zero
    }
}
