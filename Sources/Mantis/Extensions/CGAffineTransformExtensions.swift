//
//  CGAffineTransformExtensions.swift
//  Mantis
//
//  Created by yingtguo on 1/23/23.
//

import Foundation

extension CGAffineTransform {
    mutating func transformed(by cropInfo: CropInfo) {
        self = translatedBy(x: cropInfo.translation.x, y: cropInfo.translation.y)
        self = rotated(by: cropInfo.rotation)
        self = scaledBy(x: cropInfo.scaleX, y: cropInfo.scaleY)
    }
}
