//
//  CropViewProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import Foundation
import UIKit

protocol CropViewProtocol: UIView {
    var image: UIImage { get set }
    var aspectRatioLockEnabled: Bool { get set }
    var delegate: CropViewDelegate? { get set }
    
    func initialSetup(delegate: CropViewDelegate, presetFixedRatioType: PresetFixedRatioType)
    func setViewDefaultProperties()
    func getRatioType(byImageIsOriginalisHorizontal isHorizontal: Bool) -> RatioType
    func getImageHorizontalToVerticalRatio() -> Double
    func resetComponents()
    func prepareForDeviceRotation()
    func handleDeviceRotated()
    func setFixedRatio(_ ratio: Double, zoom: Bool, presetFixedRatioType: PresetFixedRatioType)
    func rotateBy90(withRotateType rotateType: RotateBy90DegreeType, completion: @escaping () -> Void)
    func handleAlterCropper90Degree()
    func handlePresetFixedRatio(_ ratio: Double, transformation: Transformation)
    
    func transform(byTransformInfo transformation: Transformation, rotateDial: Bool)
    func getTransformInfo(byTransformInfo transformInfo: Transformation) -> Transformation
    func getTransformInfo(byNormalizedInfo normailizedInfo: CGRect) -> Transformation
    func processPresetTransformation(completion: (Transformation) -> Void)
        
    func horizontallyFlip()
    func verticallyFlip()
    func reset()
    func crop() -> CropOutput
    func crop(_ image: UIImage) -> CropOutput
    func asyncCrop(completion: @escaping (CropOutput) -> Void)
    
    func getCropInfo() -> CropInfo
    func getExpectedCropImageSize() -> CGSize
}

extension CropViewProtocol {
    func setViewDefaultProperties() {
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
    }
}
