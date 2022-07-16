//
//  CropBoxLockedAspectFrameUpdater.swift
//  Mantis
//
//  Created by Echo on 10/21/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation
import UIKit

struct CropBoxLockedAspectFrameUpdater {
    private var contentFrame = CGRect.zero
    private var cropOriginFrame = CGRect.zero
    private(set) var cropBoxFrame = CGRect.zero
    private var tappedEdge = CropViewOverlayEdge.none

    init(tappedEdge: CropViewOverlayEdge, contentFrame: CGRect, cropOriginFrame: CGRect, cropBoxFrame: CGRect) {
        self.tappedEdge = tappedEdge
        self.contentFrame = contentFrame
        self.cropOriginFrame = cropOriginFrame
        self.cropBoxFrame = cropBoxFrame
    }
    
    mutating func updateCropBoxFrame(xDelta: CGFloat, yDelta: CGFloat) {
        var xDelta = xDelta
        var yDelta = yDelta
        
        // Current aspect ratio of the crop box in case we need to clamp it
        let aspectRatio = (cropOriginFrame.size.width / cropOriginFrame.size.height)
        
        func updateHeightFromBothSides() {
            cropBoxFrame.size.height = cropBoxFrame.width / aspectRatio
            cropBoxFrame.origin.y = cropOriginFrame.midY - (cropBoxFrame.height * 0.5)
        }
        
        func updateWidthFromBothSides() {
            cropBoxFrame.size.width = cropBoxFrame.height * aspectRatio
            cropBoxFrame.origin.x = cropOriginFrame.midX - cropBoxFrame.width * 0.5
        }
        
        func handleLeftEdgeFrameUpdate() {
            updateHeightFromBothSides()
            xDelta = max(0, xDelta)
            cropBoxFrame.origin.x = cropOriginFrame.origin.x + xDelta
            cropBoxFrame.size.width = cropOriginFrame.width - xDelta
            cropBoxFrame.size.height = cropBoxFrame.size.width / aspectRatio
        }
        
        func handleRightEdgeFrameUpdate() {
            updateHeightFromBothSides()
            cropBoxFrame.size.width = min(cropOriginFrame.width + xDelta, contentFrame.height * aspectRatio)
            cropBoxFrame.size.height = cropBoxFrame.size.width / aspectRatio
        }
        
        func handleTopEdgeFrameUpdate() {
            updateWidthFromBothSides()
            yDelta = max(0, yDelta)
            cropBoxFrame.origin.y = cropOriginFrame.origin.y + yDelta
            cropBoxFrame.size.height = cropOriginFrame.height - yDelta
            cropBoxFrame.size.width = cropBoxFrame.size.height * aspectRatio
        }
        
        func handleBottomEdgeFrameUpdate() {
            updateWidthFromBothSides()
            cropBoxFrame.size.height = min(cropOriginFrame.height + yDelta, contentFrame.width / aspectRatio)
            cropBoxFrame.size.width = cropBoxFrame.size.height * aspectRatio
        }
        
        let tappedEdgeCropFrameUpdateRule: TappedEdgeCropFrameUpdateRule = [.topLeft: (xDelta, yDelta),
                                                                              .topRight: (-xDelta, yDelta),
                                                                              .bottomLeft: (xDelta, -yDelta),
                                                                              .bottomRight: (-xDelta, -yDelta)]
        
        func setCropBoxSize() {
            guard let delta = tappedEdgeCropFrameUpdateRule[tappedEdge] else {
                return
            }
            
            var distance = CGPoint()
            distance.x = 1.0 - (delta.xDelta / cropOriginFrame.width)
            distance.y = 1.0 - (delta.yDelta / cropOriginFrame.height)
            let scale = (distance.x + distance.y) * 0.5
            
            cropBoxFrame.size.width = ceil(cropOriginFrame.width * scale)
            cropBoxFrame.size.height = ceil(cropOriginFrame.height * scale)
        }
        
        func handleTopLeftEdgeFrameUpdate() {
            xDelta = max(0, xDelta)
            yDelta = max(0, yDelta)
            
            setCropBoxSize()
            cropBoxFrame.origin.x = cropOriginFrame.origin.x + (cropOriginFrame.width - cropBoxFrame.width)
            cropBoxFrame.origin.y = cropOriginFrame.origin.y + (cropOriginFrame.height - cropBoxFrame.height)
        }

        func handleTopRightEdgeFrameUpdate() {
            xDelta = max(0, xDelta)
            yDelta = max(0, yDelta)
            
            setCropBoxSize()
            cropBoxFrame.origin.y = cropOriginFrame.origin.y + (cropOriginFrame.height - cropBoxFrame.height)
        }
        
        func handleBottomLeftEdgeFrameUpdate() {
            setCropBoxSize()
            cropBoxFrame.origin.x = cropOriginFrame.maxX - cropBoxFrame.width
        }
        
        func handleBottomRightEdgeFrameUpdate() {
            setCropBoxSize()
        }
        
        func updateCropBoxFrame() {
            switch tappedEdge {
            case .left:
                handleLeftEdgeFrameUpdate()
            case .right:
                handleRightEdgeFrameUpdate()
            case .top:
                handleTopEdgeFrameUpdate()
            case .bottom:
                handleBottomEdgeFrameUpdate()
            case .topLeft:
                handleTopLeftEdgeFrameUpdate()
            case .topRight:
                handleTopRightEdgeFrameUpdate()
            case .bottomLeft:
                handleBottomLeftEdgeFrameUpdate()
            case .bottomRight:
                handleBottomRightEdgeFrameUpdate()
            default:
                print("none")
            }
        }
        
        updateCropBoxFrame()
    }
}
