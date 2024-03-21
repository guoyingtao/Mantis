//
//  ImageStatus.swift
//  Mantis
//
//  Created by Echo on 10/26/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

enum ImageRotationType: CGFloat {
    case none = 0
    case counterclockwise90 = -90
    case counterclockwise180 = -180
    case counterclockwise270 = -270
    
    mutating func counterclockwiseRotate90() {
        if self == .counterclockwise270 {
            self = .none
        } else {
            self = ImageRotationType(rawValue: self.rawValue - 90) ?? .none
        }
    }
    
    mutating func clockwiseRotate90() {
        switch self {
        case .counterclockwise90:
            self = .none
        case .counterclockwise180:
            self = .counterclockwise90
        case .counterclockwise270:
            self = .counterclockwise180
        case .none:
            self = .counterclockwise270
        }
    }
    
    var isRotatedByMultiple180: Bool {
        return self == .none || self == .counterclockwise180
    }
}

final class CropViewModel: CropViewModelProtocol {
    init(
        cropViewPadding: CGFloat,
        hotAreaUnit: CGFloat
    ) {
        self.cropViewPadding = cropViewPadding
        self.hotAreaUnit = hotAreaUnit
    }

    var statusChanged: (_ status: CropViewStatus) -> Void = { _ in }
    
    var viewStatus: CropViewStatus = .initial {
        didSet {
            statusChanged(viewStatus)
        }
    }
    
    var cropBoxFrameChanged: (_ frame: CGRect) -> Void = { _ in }
    
    var cropBoxFrame = CGRect.zero {
        didSet {
            if oldValue != cropBoxFrame {
                cropBoxFrameChanged(cropBoxFrame)
            }
        }
    }
    var cropBoxOriginFrame = CGRect.zero
    var panOriginPoint = CGPoint.zero
    var tappedEdge = CropViewAuxiliaryIndicatorHandleType.none
    
    var degrees: CGFloat = 0
    
    var radians: CGFloat {
        degrees * CGFloat.pi / 180
    }
    
    var rotationType: ImageRotationType = .none
    var fixedImageRatio: CGFloat = -1    
    var cropLeftTopOnImage = CGPoint.zero
    var cropRightBottomOnImage = CGPoint(x: 1, y: 1)
    
    var horizontallyFlip = false
    var verticallyFlip = false

    private let cropViewPadding: CGFloat
    private let hotAreaUnit: CGFloat

    func reset(forceFixedRatio: Bool = false) {
        horizontallyFlip = false
        verticallyFlip = false
        cropBoxFrame = .zero
        degrees = 0
        rotationType = .none
        
        if forceFixedRatio == false {
            fixedImageRatio = -1
        }        
        
        cropLeftTopOnImage = .zero
        cropRightBottomOnImage = CGPoint(x: 1, y: 1)
        
        setInitialStatus()
    }
        
    func rotateBy90(withRotateType type: RotateBy90DegreeType) {
        if type == .clockwise {
            rotationType.clockwiseRotate90()
        } else {
            rotationType.counterclockwiseRotate90()
        }
    }
        
    func getTotalRadians() -> CGFloat {
        return getTotalRadians(by: radians)
    }
    
    func getRatioType(byImageIsOriginalHorizontal isHorizontal: Bool) -> RatioType {
        if isUpOrUpsideDown() {
            return isHorizontal ? .horizontal : .vertical
        } else {
            return isHorizontal ? .vertical : .horizontal
        }
    }
    
    func isUpOrUpsideDown() -> Bool {
        return rotationType == .none || rotationType == .counterclockwise180
    }

    func prepareForCrop(byTouchPoint point: CGPoint) {
        panOriginPoint = point
        cropBoxOriginFrame = cropBoxFrame
        
        tappedEdge = cropEdge(forPoint: point)
        
        if tappedEdge == .none {
            setTouchImageStatus()
        } else {
            setTouchCropboxHandleStatus()
        }
    }
    
    func resetCropFrame(by frame: CGRect) {
        cropBoxFrame = frame
        cropBoxOriginFrame = frame
    }
    
    func needCrop() -> Bool {
        return !cropBoxOriginFrame.equalTo(cropBoxFrame)
    }
        
    func getNewCropBoxFrame(withTouchPoint touchPoint: CGPoint,
                            andContentFrame contentFrame: CGRect,
                            aspectRatioLockEnabled: Bool) -> CGRect {
        var touchPoint = touchPoint
        touchPoint.x = max(contentFrame.origin.x - cropViewPadding, touchPoint.x)
        touchPoint.y = max(contentFrame.origin.y - cropViewPadding, touchPoint.y)
        
        // The delta descripes the difference between where we tapped in the beginning, and the current finger location
        let xDelta = ceil(touchPoint.x - panOriginPoint.x)
        let yDelta = ceil(touchPoint.y - panOriginPoint.y)
        
        let newCropBoxFrame: CGRect
        if aspectRatioLockEnabled {
            var cropBoxLockedAspectFrameUpdater = CropBoxLockedAspectFrameUpdater(tappedEdge: tappedEdge,
                                                                                  contentFrame: contentFrame,
                                                                                  cropOriginFrame: cropBoxOriginFrame,
                                                                                  cropBoxFrame: cropBoxFrame)
            cropBoxLockedAspectFrameUpdater.updateCropBoxFrame(xDelta: xDelta, yDelta: yDelta)
            newCropBoxFrame = cropBoxLockedAspectFrameUpdater.cropBoxFrame
        } else {
            var cropBoxFreeAspectFrameUpdater = CropBoxFreeAspectFrameUpdater(tappedEdge: tappedEdge,
                                                                              contentFrame: contentFrame,
                                                                              cropOriginFrame: cropBoxOriginFrame,
                                                                              cropBoxFrame: cropBoxFrame)
            cropBoxFreeAspectFrameUpdater.updateCropBoxFrame(xDelta: xDelta, yDelta: yDelta)
            newCropBoxFrame = cropBoxFreeAspectFrameUpdater.cropBoxFrame
        }

        return newCropBoxFrame
    }
    
    func setCropBoxFrame(by refCropBox: CGRect, for imageHorizontalToVerticalRatio: ImageHorizontalToVerticalRatio) {
        var cropBoxFrame = refCropBox
        let center = cropBoxFrame.center
        
        if fixedImageRatio > CGFloat(imageHorizontalToVerticalRatio.ratio) {
            cropBoxFrame.size.height = cropBoxFrame.width / fixedImageRatio
        } else {
            cropBoxFrame.size.width = cropBoxFrame.height * fixedImageRatio
        }
        
        cropBoxFrame.origin.x = center.x - cropBoxFrame.width / 2
        cropBoxFrame.origin.y = center.y - cropBoxFrame.height / 2
        
        self.cropBoxFrame = cropBoxFrame
    }
}

// MARK: - private
extension CropViewModel {
    private func counterclockwiseRotateBy90() {
        rotationType.counterclockwiseRotate90()
    }
    
    private func clockwiseRotateBy90() {
        rotationType.clockwiseRotate90()
    }
    
    private func getTotalRadians(by radians: CGFloat) -> CGFloat {
        return radians + rotationType.rawValue * CGFloat.pi / 180
    }
    
    private func cropEdge(forPoint point: CGPoint) -> CropViewAuxiliaryIndicatorHandleType {
        let touchRect = cropBoxFrame.insetBy(dx: -hotAreaUnit / 2, dy: -hotAreaUnit / 2)
        return GeometryHelper.getCropEdge(forPoint: point, byTouchRect: touchRect, hotAreaUnit: hotAreaUnit)
    }
}
