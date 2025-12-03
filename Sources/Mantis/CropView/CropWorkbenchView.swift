//
//  CropWorkbenchView.swift
//  Mantis
//
//  Created by Yingtao Guo on 10/20/18.
//  Copyright © 2018 Echo Studio. All rights reserved.
//

import UIKit

final class CropWorkbenchView: UIScrollView {
    var imageContainer: ImageContainerProtocol?
    
    var touchesBegan = {}
    var touchesCancelled = {}
    var touchesEnded = {}
    
    private var initialMinimumZoomScale: CGFloat = 1.0
    
    deinit {
        print("CropWorkbenchView deinit")
    }
    
    init(frame: CGRect,
         minimumZoomScale: CGFloat,
         maximumZoomScale: CGFloat,
         imageContainer: ImageContainerProtocol) {
        super.init(frame: frame)
        
        alwaysBounceHorizontal = true
        alwaysBounceVertical = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        clipsToBounds = false
        contentSize = bounds.size
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        self.minimumZoomScale = minimumZoomScale
        self.maximumZoomScale = maximumZoomScale
        initialMinimumZoomScale = minimumZoomScale
        self.imageContainer = imageContainer
        addSubview(self.imageContainer!)
        
        isAccessibilityElement = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
    private func getBoundZoomScale() -> CGFloat {
        guard let imageContainer = imageContainer else {
            assertionFailure("We must have an imageContainer")
            return 1.0
        }
        
        let scaleW = bounds.width / imageContainer.bounds.width
        let scaleH = bounds.height / imageContainer.bounds.height
        
        return max(scaleW, scaleH) * initialMinimumZoomScale
    }
}

extension CropWorkbenchView: CropWorkbenchViewProtocol {
    func updateContentOffset() {
        contentOffset.x = max(contentOffset.x, 0)
        contentOffset.y = max(contentOffset.y, 0)        
        contentOffset.x = min(contentOffset.x, contentSize.width - bounds.size.width)
        contentOffset.y = min(contentOffset.y, contentSize.height - bounds.size.height)
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
    
    func reset(by rect: CGRect) {
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
    
    func resetImageContent(by cropBoxFrame: CGRect) {
        transform = .identity
        reset(by: cropBoxFrame)
        
        guard let imageContainer = imageContainer else {
            assertionFailure("We must have an imageContainer")
            return
        }
        
        imageContainer.frame = CGRect(x: 0,
                                      y: 0,
                                      width: contentSize.width,
                                      height: contentSize.height)
        
        contentOffset = CGPoint(x: (imageContainer.frame.width - frame.width) / 2,
                                y: (imageContainer.frame.height - frame.height) / 2)
    }
    
    func zoomIn(by zoomScaleFactor: CGFloat) {
        let newZoomScale = min(zoomScale * zoomScaleFactor, maximumZoomScale)
        setZoomScale(newZoomScale, animated: true)
    }
    
    func zoomOut(by zoomScaleFactor: CGFloat) {
        let newZoomScale = max(zoomScale / zoomScaleFactor, minimumZoomScale)
        setZoomScale(newZoomScale, animated: true)
    }
}
