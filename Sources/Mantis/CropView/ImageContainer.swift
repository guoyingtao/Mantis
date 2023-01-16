//
//  ImageContainer.swift
//  Mantis
//
//  Created by Echo on 10/29/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class ImageContainer: UIView {

    lazy private var imageView: UIImageView = {
        let imageView = UIImageView(frame: bounds)
        imageView.layer.minificationFilter = .trilinear
        imageView.accessibilityIgnoresInvertColors = true
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        addSubview(imageView)
        
        return imageView
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}

extension ImageContainer: ImageContainerProtocol {
    func setup(with image: UIImage) {
        imageView.frame = bounds
        imageView.image = image
    }

    func contains(rect: CGRect, fromView view: UIView, tolerance: CGFloat = 0.5) -> Bool {
        let newRect = view.convert(rect, to: self)
        
        let point1 = newRect.origin
        let point2 = CGPoint(x: newRect.maxX, y: newRect.maxY)
        
        let refBounds = bounds.insetBy(dx: -tolerance, dy: -tolerance)
        
        return refBounds.contains(point1) && refBounds.contains(point2)
    }
}
