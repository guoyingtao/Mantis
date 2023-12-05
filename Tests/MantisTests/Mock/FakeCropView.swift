//
//  FakeCropView.swift
//  Mantis
//
//  Created by Yingtao Guo on 2/2/23.
//

import UIKit
@testable import Mantis

class FakeCropView: UIView, CropViewProtocol {
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
        Transformation(.zero, .zero, .zero, false, .zero, .zero, .zero, false, false)
    }
    
    func getTransformInfo(byNormalizedInfo normalizedInfo: CGRect) -> Transformation {
        Transformation(.zero, .zero, .zero, false, .zero, .zero, .zero, false, false)
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
        return Transformation(.zero, .zero, .zero, false, .zero, .zero, .zero, false, false)
    }
    
    func crop() -> CropOutput {
        CropOutput(nil,
                   Transformation(.zero, .zero, .zero, false, .zero, .zero, .zero, false, false),
                   CropInfo(.zero, .zero, .zero, .zero, .zero, .zero,
                            CropRegion(topLeft: .zero,
                                       topRight: .zero,
                                       bottomLeft: .zero,
                                       bottomRight: .zero)))
    }
    
    func crop(_ image: UIImage) -> CropOutput {
        CropOutput(nil,
                   Transformation(.zero, .zero, .zero, false, .zero, .zero, .zero, false, false),
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
