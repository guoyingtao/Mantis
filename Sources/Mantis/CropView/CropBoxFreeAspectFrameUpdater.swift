//
//  CropBoxFreeAspectFrameUpdater.swift
//  Mantis
//
//  Created by Echo on 10/21/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

struct CropBoxFreeAspectFrameUpdater {
    var minimumAspectRatio = CGFloat(0)
    
    private var contentFrame = CGRect.zero
    private var cropOriginFrame = CGRect.zero
    private(set) var cropBoxFrame = CGRect.zero
    private var tappedEdge = CropViewAuxiliaryIndicatorHandleType.none
    
    init(tappedEdge: CropViewAuxiliaryIndicatorHandleType, contentFrame: CGRect, cropOriginFrame: CGRect, cropBoxFrame: CGRect) {
        self.tappedEdge = tappedEdge
        self.contentFrame = contentFrame
        self.cropOriginFrame = cropOriginFrame
        self.cropBoxFrame = cropBoxFrame
    }
    
    mutating func updateCropBoxFrame(xDelta: CGFloat, yDelta: CGFloat) {
        func newAspectRatioValid(withNewSize newSize: CGSize) -> Bool {
            return min(newSize.width, newSize.height) / max(newSize.width, newSize.height) >= minimumAspectRatio
        }
        
        func handleLeftEdgeFrameUpdate(newSize: CGSize) {
            if newAspectRatioValid(withNewSize: newSize) {
                cropBoxFrame.origin.x = cropOriginFrame.origin.x + xDelta
                cropBoxFrame.size.width = newSize.width
            }
        }
        
        func handleRightEdgeFrameUpdate(newSize: CGSize) {
            if newAspectRatioValid(withNewSize: newSize) {
                cropBoxFrame.size.width = newSize.width
            }
        }
        
        func handleTopEdgeFrameUpdate(newSize: CGSize) {
            if newAspectRatioValid(withNewSize: newSize) {
                cropBoxFrame.origin.y = cropOriginFrame.origin.y + yDelta
                cropBoxFrame.size.height = newSize.height
            }
        }
        
        func handleBottomEdgeFrameUpdate(newSize: CGSize) {
            if newAspectRatioValid(withNewSize: newSize) {
                cropBoxFrame.size.height = newSize.height
            }
        }
        
        func getNewCropFrameSize(byTappedEdge tappedEdge: CropViewAuxiliaryIndicatorHandleType) -> CGSize {
            let tappedEdgeCropFrameUpdateRule: TappedEdgeCropFrameUpdateRule = [.left: (-xDelta, 0),
                                                                                .right: (xDelta, 0),
                                                                                .top: (0, -yDelta),
                                                                                .bottom: (0, yDelta),
                                                                                .topLeft: (-xDelta, -yDelta),
                                                                                .topRight: (xDelta, -yDelta),
                                                                                .bottomLeft: (-xDelta, yDelta),
                                                                                .bottomRight: (xDelta, yDelta)]
            
            guard let delta = tappedEdgeCropFrameUpdateRule[tappedEdge] else {
                return cropOriginFrame.size
            }
            
            return CGSize(width: cropOriginFrame.width + delta.xDelta, height: cropOriginFrame.height + delta.yDelta)
        }
        
        func updateCropBoxFrame() {
            let newSize = getNewCropFrameSize(byTappedEdge: tappedEdge)

            switch tappedEdge {
            case .left:
                handleLeftEdgeFrameUpdate(newSize: newSize)
            case .right:
                handleRightEdgeFrameUpdate(newSize: newSize)
            case .top:
                handleTopEdgeFrameUpdate(newSize: newSize)
            case .bottom:
                handleBottomEdgeFrameUpdate(newSize: newSize)
            case .topLeft:
                handleTopEdgeFrameUpdate(newSize: newSize)
                handleLeftEdgeFrameUpdate(newSize: newSize)
            case .topRight:
                handleTopEdgeFrameUpdate(newSize: newSize)
                handleRightEdgeFrameUpdate(newSize: newSize)
            case .bottomLeft:
                handleBottomEdgeFrameUpdate(newSize: newSize)
                handleLeftEdgeFrameUpdate(newSize: newSize)
            case .bottomRight:
                handleBottomEdgeFrameUpdate(newSize: newSize)
                handleRightEdgeFrameUpdate(newSize: newSize)
            default:
                return
            }
        }
        
        updateCropBoxFrame()
    }
}
