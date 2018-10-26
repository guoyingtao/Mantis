//
//  ImageStatus.swift
//  Mantis
//
//  Created by Echo on 10/26/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

enum ImageRotationType {
    case none
    case clockwise90
    case clockwise180
    case clockwish270
}

struct ImageStatus {
    var angle: CGFloat = 0
    var zoomScale: CGFloat = 0
    var offset: CGPoint = .zero
    var rotationType: ImageRotationType = .none    
}
