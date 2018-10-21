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
    
    init(contentFrame: CGRect) {
        self.contentFrame = contentFrame
    }
    
    func clamp(cropBoxFrame: CGRect, withOriginalFrame originalFrame: CGRect, andUpdateCropBoxFrameInfo info: UpdateCropBoxFrameInfo) -> CGRect {
        
        var cropBoxFrame = cropBoxFrame
        
        //The absolute max/min size the box may be in the bounds of the crop view
        let minSize = CGSize(width: cropViewMinimumBoxSize, height: cropViewMinimumBoxSize)
        let maxSize = contentFrame.size
        
        //clamp the box to ensure it doesn't go beyond the bounds we've set
        
        
        // Clamp the width if it goes over
        
        //Clamp the minimum size
        
        //Clamp the maximum size
        
        //Clamp the X position of the box to the interior of the cropping bounds
        
        //Clamp the Y postion of the box to the interior of the cropping bounds
        
        //Once the box is completely shrunk, clamp its ability to move
        
        //Once the box is completely shrunk, clamp its ability to move
        
        return cropBoxFrame
    }

}
