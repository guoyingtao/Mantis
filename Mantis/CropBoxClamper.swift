//
//  CropBoxClamper.swift
//  Mantis
//
//  Created by Echo on 10/21/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation
import UIKit

struct CropBoxClamper {
    let cropViewMinimumBoxSize = CGFloat(42)

    private var contentFrame = CGRect.zero
    private var cropOriginFrame = CGRect.zero
    private var cropBoxFrame = CGRect.zero
    
    init(contentFrame: CGRect, cropOriginFrame: CGRect, cropBoxFrame: CGRect) {
        self.contentFrame = contentFrame
        self.cropOriginFrame = cropOriginFrame
        self.cropBoxFrame = cropBoxFrame
    }
    
    func clamp(cropBoxFrame: CGRect, withOriginalFrame originalFrame: CGRect, andUpdateCropBoxFrameInfo info: UpdateCropBoxFrameInfo) -> CGRect {
        
        var cropBoxFrame = cropBoxFrame
        
        //The absolute max/min size the box may be in the bounds of the crop view
        var minSize = CGSize(width: cropViewMinimumBoxSize, height: cropViewMinimumBoxSize)
        var maxSize = contentFrame.size
        
        let aspectRatio = (cropOriginFrame.size.width / cropOriginFrame.size.height);
        //clamp the box to ensure it doesn't go beyond the bounds we've set
        if info.aspectHorizontal {
            maxSize.height = contentFrame.size.width / aspectRatio
            minSize.width = cropViewMinimumBoxSize * aspectRatio
        }
        
        if info.aspectVertical {
            maxSize.width = contentFrame.size.height * aspectRatio
            minSize.height = cropViewMinimumBoxSize / aspectRatio
        }
        
        // Clamp the width if it goes over
        if info.clampMinFromLeft {
            let maxWidth = cropBoxFrame.maxX - contentFrame.origin.x
            cropBoxFrame.size.width = min(cropBoxFrame.width, maxWidth);
        }
        
        // Clamp the height if it goes over
        if info.clampMinFromTop {
            let maxHeight = cropBoxFrame.maxY - contentFrame.origin.y
            cropBoxFrame.size.height = min(cropBoxFrame.height, maxHeight)
        }
        
        //Clamp the minimum size
        cropBoxFrame.size.width = max(cropBoxFrame.width, minSize.width)
        cropBoxFrame.size.height = max(contentFrame.height, minSize.height)
        
        //Clamp the maximum size
        cropBoxFrame.size.width = min(cropBoxFrame.width, maxSize.width)
        cropBoxFrame.size.height = min(contentFrame.height, maxSize.height)
        
        //Clamp the X position of the box to the interior of the cropping bounds
        cropBoxFrame.origin.x = max(cropBoxFrame.origin.x, contentFrame.minX)
        cropBoxFrame.origin.x = min(cropBoxFrame.origin.x, contentFrame.maxX - minSize.width)
        
        //Clamp the Y postion of the box to the interior of the cropping bounds
        cropBoxFrame.origin.y = max(cropBoxFrame.origin.y, contentFrame.minY)
        cropBoxFrame.origin.y = min(cropBoxFrame.origin.y, contentFrame.maxY - minSize.height)

        //Once the box is completely shrunk, clamp its ability to move
        if (info.clampMinFromLeft && cropBoxFrame.width <= minSize.width + CGFloat(Float.ulpOfOne)) {
            cropBoxFrame.origin.x = cropOriginFrame.maxX - minSize.width;
        }
        
        //Once the box is completely shrunk, clamp its ability to move
        if (info.clampMinFromTop && cropBoxFrame.height <= minSize.height + CGFloat(Float.ulpOfOne)) {
            cropBoxFrame.origin.y = cropOriginFrame.maxY - minSize.height;
        }
        
        return cropBoxFrame
    }

}
