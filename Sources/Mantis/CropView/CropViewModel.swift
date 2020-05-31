//
//  ImageStatus.swift
//  Mantis
//
//  Created by Echo on 10/26/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

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
}

class CropViewModel: NSObject {
    var statusChanged: (_ status: CropViewStatus)->Void = { _ in }
    
    var viewStatus: CropViewStatus = .initial {
        didSet {
            self.statusChanged(viewStatus)
        }
    }
    
    @objc dynamic var cropBoxFrame = CGRect.zero
    var cropOrignFrame = CGRect.zero
    
    var panOriginPoint = CGPoint.zero
    var tappedEdge = CropViewOverlayEdge.none
    
    var degrees: CGFloat = 0
    
    var radians: CGFloat {
        get {
          return degrees * CGFloat.pi / 180
        }
    }
    
    var rotationType: ImageRotationType = .none
    var aspectRatio: CGFloat = -1    
    var cropLeftTopOnImage: CGPoint = .zero
    var cropRightBottomOnImage: CGPoint = CGPoint(x: 1, y: 1)
    
    func reset(forceFixedRatio: Bool = false) {
        cropBoxFrame = .zero
        degrees = 0
        rotationType = .none
        
        if forceFixedRatio == false {
            aspectRatio = -1
        }        
        
        cropLeftTopOnImage = .zero
        cropRightBottomOnImage = CGPoint(x: 1, y: 1)
        
        setInitialStatus()
    }
    
    func rotateBy90() {
        rotationType.counterclockwiseRotate90()
    }
    
    func getTotalRadias(by radians: CGFloat) -> CGFloat {
        return radians + rotationType.rawValue * CGFloat.pi / 180
    }
    
    func getTotalRadians() -> CGFloat {
        return getTotalRadias(by: radians)
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
        cropOrignFrame = cropBoxFrame
        
        tappedEdge = cropEdge(forPoint: point)
        
        if tappedEdge == .none {
            setTouchImageStatus()
        } else {
            setTouchCropboxHandleStatus()
        }
    }
    
    func resetCropFrame(by frame: CGRect) {
        cropBoxFrame = frame
        cropOrignFrame = frame
    }
    
    func needCrop() -> Bool {
        return !cropOrignFrame.equalTo(cropBoxFrame)
    }
    
    func cropEdge(forPoint point: CGPoint) -> CropViewOverlayEdge {
        let touchRect = cropBoxFrame.insetBy(dx: -hotAreaUnit / 2, dy: -hotAreaUnit / 2)
        return GeometryHelper.getCropEdge(forPoint: point, byTouchRect: touchRect, hotAreaUnit: hotAreaUnit)
    }
    
    func getNewCropBoxFrame(with point: CGPoint, and contentFrame: CGRect, aspectRatioLockEnabled: Bool) -> CGRect {
        var point = point
        point.x = max(contentFrame.origin.x - cropViewPadding, point.x)
        point.y = max(contentFrame.origin.y - cropViewPadding, point.y)
        
        //The delta between where we first tapped, and where our finger is now
        let xDelta = ceil(point.x - panOriginPoint.x)
        let yDelta = ceil(point.y - panOriginPoint.y)
        
        let newCropBoxFrame: CGRect
        if aspectRatioLockEnabled {
            var cropBoxLockedAspectFrameUpdater = CropBoxLockedAspectFrameUpdater(tappedEdge: tappedEdge, contentFrame: contentFrame, cropOriginFrame: cropOrignFrame, cropBoxFrame: cropBoxFrame)
            cropBoxLockedAspectFrameUpdater.updateCropBoxFrame(xDelta: xDelta, yDelta: yDelta)
            newCropBoxFrame = cropBoxLockedAspectFrameUpdater.cropBoxFrame
        } else {
            var cropBoxFreeAspectFrameUpdater = CropBoxFreeAspectFrameUpdater(tappedEdge: tappedEdge, contentFrame: contentFrame, cropOriginFrame: cropOrignFrame, cropBoxFrame: cropBoxFrame)
            cropBoxFreeAspectFrameUpdater.updateCropBoxFrame(xDelta: xDelta, yDelta: yDelta)
            newCropBoxFrame = cropBoxFreeAspectFrameUpdater.cropBoxFrame
        }

        return newCropBoxFrame
    }
    
    func setCropBoxFrame(by initialCropBox: CGRect, and imageRationH: Double) {
        var cropBoxFrame = initialCropBox
        let center = cropBoxFrame.center
        
        if (aspectRatio > CGFloat(imageRationH)) {
            cropBoxFrame.size.height = cropBoxFrame.width / aspectRatio
        } else {
            cropBoxFrame.size.width = cropBoxFrame.height * aspectRatio
        }
        
        cropBoxFrame.origin.x = center.x - cropBoxFrame.width / 2
        cropBoxFrame.origin.y = center.y - cropBoxFrame.height / 2
        
        self.cropBoxFrame = cropBoxFrame
    }
}

// MARK: - Handle view status changes
extension CropViewModel {
    func setInitialStatus() {
        viewStatus = .initial
    }
    
    func setRotatingStatus(by angle: CGAngle) {
        viewStatus = .rotating(angle: angle)
    }
    
    func setDegree90RotatingStatus() {
        viewStatus = .degree90Rotating
    }
    
    func setTouchImageStatus() {
        viewStatus = .touchImage
    }

    func setTouchRotationBoardStatus() {
        viewStatus = .touchRotationBoard
    }

    func setTouchCropboxHandleStatus() {
        viewStatus = .touchCropboxHandle(tappedEdge: tappedEdge)
    }
    
    func setBetweenOperationStatus() {
        viewStatus = .betweenOperation
    }
}
