//
//  CropBoxLockedAspectFrameUpdater.swift
//  Mantis
//
//  Created by Echo on 10/21/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation
import UIKit

//Depending on which corner we drag from, set the appropriate min flag to
typealias CropBoxFrameAspectInfo = (aspectHorizontal: Bool, aspectVertical: Bool)

struct CropBoxLockedAspectFrameUpdater {
    func updateCropBoxFrame(xDelta: CGFloat, yDelta: CGFloat) -> CropBoxFrameAspectInfo {
        var xDelta = xDelta
        var yDelta = yDelta

        var cropBoxFrameAspectInfo = CropBoxFrameAspectInfo(false, false)
        return cropBoxFrameAspectInfo
    }
}
