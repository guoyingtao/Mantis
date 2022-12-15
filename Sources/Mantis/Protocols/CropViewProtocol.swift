//
//  CropViewProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import Foundation
import UIKit

protocol CropViewProtocol: AnyObject {
    var image: UIImage { get set }
    var aspectRatioLockEnabled: Bool { get set }
    var delegate: CropViewDelegate? { get set }
    
    func setViewDefaultProperties()
    func getRatioType(byImageIsOriginalisHorizontal isHorizontal: Bool) -> RatioType
    func getImageRatioH() -> Double
    func adaptForCropBox()
    func prepareForDeviceRotation()
    func handleDeviceRotated()
    func setFixedRatioCropBox(zoom: Bool)
    func rotateBy90(rotateAngle: CGFloat, completion: @escaping () -> Void)
    func handleAlterCropper90Degree()
    func handlePresetFixedRatio(_ ratio: Double, transformation: Transformation)
    func setFixedRatio(_ ratio: Double, zoom: Bool, alwaysUsingOnePresetFixedRatio: Bool)
    
    func transform(byTransformInfo transformation: Transformation, rotateDial: Bool)
    func getTransformInfo(byTransformInfo transformInfo: Transformation) -> Transformation
    func getTransformInfo(byNormalizedInfo normailizedInfo: CGRect) -> Transformation
    func processPresetTransformation(completion: (Transformation) -> Void)
        
    func horizontallyFlip()
    func verticallyFlip()
    func reset()
    func crop() -> CropOutput
    func asyncCrop(completiom: (_ cropOutput: CropOutput) -> Void)
    
    func getCropInfo() -> CropInfo
    func getExpectedCropImageSize() -> CGSize
}

extension CropViewProtocol where Self: UIView {
    func setViewDefaultProperties() {
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
    }
}
