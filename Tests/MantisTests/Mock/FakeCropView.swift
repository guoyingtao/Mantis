//
//  FakeCropView.swift
//  Mantis
//
//  Created by Yingtao Guo on 2/2/23.
//

import UIKit
@testable import Mantis

class FakeCropView: UIView, CropViewProtocol {
    static func makeState(degrees: CGFloat = 0,
                          rotationType: ImageRotationType = .none,
                          aspectRatioLockEnabled: Bool = false,
                          aspectRatio: CGFloat = 0,
                          flipOddTimes: Bool = false,
                          horizontalSkewDegrees: CGFloat = 0,
                          verticalSkewDegrees: CGFloat = 0) -> CropState {
        CropState(
            rotationType: rotationType,
            degrees: degrees,
            aspectRatioLockEnabled: aspectRatioLockEnabled,
            aspectRato: aspectRatio,
            flipOddTimes: flipOddTimes,
            transformation: makeEmptyTransformation(),
            horizontalSkewDegrees: horizontalSkewDegrees,
            verticalSkewDegrees: verticalSkewDegrees
        )
    }

    static func makeEmptyTransformation() -> Transformation {
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

    /// Returned by makeCropState(). Change it between calls to simulate a user edit.
    var cropState = FakeCropView.makeState()

    /// When set, reset() switches cropState to it, as a real reset would.
    var cropStateAfterReset: CropState?

    /// The image returned by crop() and crop(_:). nil simulates a failed crop.
    var croppedImage: UIImage?

    var imageHorizontalToVerticalRatio: Double = 0

    private(set) var appliedCropStates: [CropState] = []
    private(set) var resetCallCount = 0
    private(set) var setFreeCropCallCount = 0
    private(set) var horizontallyFlipCallCount = 0
    private(set) var verticallyFlipCallCount = 0
    private(set) var setFixedRatioCalls: [(ratio: Double, zoom: Bool)] = []
    private(set) var rotateBy90Types: [RotateBy90DegreeType] = []
    /// Completions of rotateBy90 calls, in call order. Call one to finish that rotation.
    private(set) var pendingRotationCompletions: [() -> Void] = []
    private(set) var cropCallCount = 0
    /// Completions of asyncCrop calls, in call order. Call one to finish that crop.
    private(set) var pendingAsyncCropCompletions: [(CropOutput) -> Void] = []

    func applyCropState(with cropState: Mantis.CropState) {
        appliedCropStates.append(cropState)
    }

    func makeCropState() -> Mantis.CropState {
        cropState
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
        imageHorizontalToVerticalRatio
    }
    
    func resetComponents() {
        
    }
    
    var prepareForViewWillTransitionCallCount = 0
    var handleViewWillTransitionCallCount = 0
    var onHandleViewWillTransition: (() -> Void)?

    func prepareForViewWillTransition() {
        prepareForViewWillTransitionCallCount += 1
    }

    func handleViewWillTransition() {
        handleViewWillTransitionCallCount += 1
        onHandleViewWillTransition?()
    }

    func setFixedRatio(_ ratio: Double, zoom: Bool, presetFixedRatioType: PresetFixedRatioType) {
        setFixedRatioCalls.append((ratio, zoom))
    }

    func rotateBy90(withRotateType rotateType: RotateBy90DegreeType, completion: @escaping () -> Void) {
        rotateBy90Types.append(rotateType)
        pendingRotationCompletions.append(completion)
    }
    
    func handleAlterCropper90Degree() {
        
    }
    
    func setFreeCrop() {
        setFreeCropCallCount += 1
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
        horizontallyFlipCallCount += 1
    }

    func verticallyFlip() {
        verticallyFlipCallCount += 1
    }

    func reset() {
        resetCallCount += 1
        if let cropStateAfterReset {
            cropState = cropStateAfterReset
        }
    }
    
    func makeCropInfo() -> CropInfo {
        CropInfo(translation: .zero, rotation: .zero,
                 scaleX: .zero, scaleY: .zero,
                 cropSize: .zero, imageViewSize: .zero,
                 cropRegion: CropRegion(topLeft: .zero, topRight: .zero,
                                        bottomLeft: .zero, bottomRight: .zero))
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
        cropCallCount += 1
        return CropOutput(croppedImage,
                   Transformation(offset: .zero, 
                                  rotation: .zero,
                                  scale: .zero,
                                  isManuallyZoomed: false,
                                  initialMaskFrame: .zero,
                                  maskFrame: .zero,
                                  cropWorkbenchViewBounds: .zero,
                                  horizontallyFlipped: false,
                                  verticallyFlipped: false),
                   makeCropInfo())
    }
    
    func crop(_ image: UIImage) -> CropOutput {
        CropOutput(croppedImage,
                   Transformation(offset: .zero, 
                                  rotation: .zero,
                                  scale: .zero,
                                  isManuallyZoomed: false,
                                  initialMaskFrame: .zero,
                                  maskFrame: .zero,
                                  cropWorkbenchViewBounds: .zero,
                                  horizontallyFlipped: false,
                                  verticallyFlipped: false),
                   makeCropInfo())
    }
    
    func asyncCrop(completion: @escaping (CropOutput) -> Void) {
        pendingAsyncCropCompletions.append(completion)
    }
    
    func getCropInfo() -> CropInfo {
        makeCropInfo()
    }
    
    func getExpectedCropImageSize() -> CGSize {
        .zero
    }
}
