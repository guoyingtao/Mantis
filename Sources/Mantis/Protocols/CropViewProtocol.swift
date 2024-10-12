//
//  CropViewProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import Foundation
import UIKit

public protocol ActivityIndicatorProtocol: UIView {
    func startAnimating()
    func stopAnimating()
}

protocol CropViewProtocol: UIView {
    var image: UIImage { get set }
    var aspectRatioLockEnabled: Bool { get set }
    var delegate: CropViewDelegate? { get set }
    
    func initialSetup(delegate: CropViewDelegate, presetFixedRatioType: PresetFixedRatioType)
    func setViewDefaultProperties()
    func getRatioType(byImageIsOriginalHorizontal isHorizontal: Bool) -> RatioType
    func getImageHorizontalToVerticalRatio() -> Double
    func resetComponents()
    func prepareForViewWillTransition()
    func handleViewWillTransition()
    func setFixedRatio(_ ratio: Double, zoom: Bool, presetFixedRatioType: PresetFixedRatioType)
    func rotateBy90(withRotateType rotateType: RotateBy90DegreeType, completion: @escaping () -> Void)
    func handleAlterCropper90Degree()
    func handlePresetFixedRatio(_ ratio: Double, transformation: Transformation)
    func applyCropState(with cropState: CropState)
    func transform(byTransformInfo transformation: Transformation, isUpdateRotationControlView: Bool)
    func getTransformInfo(byTransformInfo transformInfo: Transformation) -> Transformation
    func getTransformInfo(byNormalizedInfo normalizedInfo: CGRect) -> Transformation
    func processPresetTransformation(completion: (Transformation) -> Void)
        
    func setFreeCrop()
    func horizontallyFlip()
    func verticallyFlip()
    func reset()
    func crop() -> CropOutput
    func crop(_ image: UIImage) -> CropOutput
    func asyncCrop(completion: @escaping (CropOutput) -> Void)
    
    func getCropInfo() -> CropInfo
    func getExpectedCropImageSize() -> CGSize
    
    func rotate(by angle: Angle)
    func makeTransformation() -> Transformation
    func makeCropState() -> CropState
    
    func update(_ image: UIImage)
    
    func zoomIn()
    func zoomOut()
}

extension CropViewProtocol {
    func setViewDefaultProperties() {
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func rotate(by angle: Angle) {}
    
    func update(_ image: UIImage) {}
    
    func zoomIn() {}    
    func zoomOut() {}
}
