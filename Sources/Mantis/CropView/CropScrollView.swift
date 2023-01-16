//
//  CropScrollView.swift
//  Mantis
//
//  Created by Echo on 10/20/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropScrollView: UIScrollView {
    
    weak var imageContainer: ImageContainerProtocol?
    
    var touchesBegan = {}
    var touchesCancelled = {}
    var touchesEnded = {}
    
    private var initialMinimumZoomScale: CGFloat = 1.0
    
    init(frame: CGRect, minimumZoomScale: CGFloat = 1.0, maximumZoomScale: CGFloat = 15.0) {
        super.init(frame: frame)
        alwaysBounceHorizontal = true
        alwaysBounceVertical = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        self.minimumZoomScale = minimumZoomScale
        self.maximumZoomScale = maximumZoomScale
        initialMinimumZoomScale = minimumZoomScale
        clipsToBounds = false
        contentSize = bounds.size
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesBegan()
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesCancelled()
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded()
        super.touchesBegan(touches, with: event)
    }
    
    func checkContentOffset() {
        contentOffset.x = max(contentOffset.x, 0)
        contentOffset.y = max(contentOffset.y, 0)
        
        if contentSize.height - contentOffset.y <= bounds.size.height {
            contentOffset.y = contentSize.height - bounds.size.height
        }
        
        if contentSize.width - contentOffset.x <= bounds.size.width {
            contentOffset.x = contentSize.width - bounds.size.width
        }
    }
    
    private func getBoundZoomScale() -> CGFloat {
        guard let imageContainer = imageContainer else {
            return 1.0
        }
        
        let scaleW = bounds.width / imageContainer.bounds.width
        let scaleH = bounds.height / imageContainer.bounds.height
        
        return max(scaleW, scaleH) * initialMinimumZoomScale
    }
    
    func updateMinZoomScale() {
        minimumZoomScale = getBoundZoomScale()
    }
    
    func zoomScaleToBound(animated: Bool = false) {
        let scale = getBoundZoomScale()
        
        minimumZoomScale = scale
        setZoomScale(scale, animated: animated)        
    }
    
    func shouldScale() -> Bool {
        return contentSize.width / bounds.width <= 1.0
            || contentSize.height / bounds.height <= 1.0
    }
    
    func updateLayout(byNewSize newSize: CGSize) {
        let oldScrollViewcenter = center
        let contentOffsetCenter = CGPoint(x: (contentOffset.x + bounds.width / 2),
                                          y: (contentOffset.y + bounds.height / 2))
        
        bounds = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        let newContentOffset = CGPoint(x: (contentOffsetCenter.x - bounds.width / 2),
                                       y: (contentOffsetCenter.y - bounds.height / 2))
        
        contentOffset = newContentOffset
        center = oldScrollViewcenter
    }
    
    func resetBy(rect: CGRect) {
        // Reseting zoom need to be before resetting frame and contentsize
        minimumZoomScale = max(1.0, initialMinimumZoomScale)
        zoomScale = minimumZoomScale
        
        let newRect = CGRect(x: rect.origin.x,
                             y: rect.origin.y,
                             width: rect.width * minimumZoomScale,
                             height: rect.height * minimumZoomScale)
        frame = rect
        contentSize = newRect.size
    }
}
