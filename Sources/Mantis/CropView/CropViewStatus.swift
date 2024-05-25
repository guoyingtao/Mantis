//
//  CropViewStatus.swift
//  Mantis
//
//  Created by Echo on 10/26/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

enum CropViewStatus: Equatable {
    case initial
    case rotating
    case degree90Rotating
    case touchImage
    case touchRotationBoard
    case touchCropboxHandle(tappedEdge: CropViewAuxiliaryIndicatorHandleType = .none)
    case betweenOperation
}
