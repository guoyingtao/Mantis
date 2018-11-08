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
        
//        layer.borderColor = UIColor.green.cgColor
//        layer.borderWidth = 2
        
        addSubview(imageView)
        
        return imageView
    } ()

    var image: UIImage? {
        didSet {
            imageView.frame = bounds
            imageView.image = image
            
            imageView.isUserInteractionEnabled = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}
