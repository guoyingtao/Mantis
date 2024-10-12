//
//  CropWorkbenchViewProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import UIKit

protocol CropWorkbenchViewProtocol: UIScrollView {
    var imageContainer: ImageContainerProtocol? { get set }
    var touchesBegan: () -> Void { get set }
    var touchesCancelled: () -> Void { get set }
    var touchesEnded: () -> Void { get set }
    
    func updateContentOffset()
    func updateMinZoomScale()
    func zoomScaleToBound(animated: Bool)
    func shouldScale() -> Bool
    func updateLayout(byNewSize newSize: CGSize)
    func reset(by rect: CGRect)
    func resetImageContent(by cropBoxFrame: CGRect)
    func transformScaleBy(xScale: CGFloat, yScale: CGFloat)
    
    func zoomIn(by zoomScaleFactor: CGFloat)
    func zoomOut(by zoomScaleFactor: CGFloat)
}

extension CropWorkbenchViewProtocol {
    func transformScaleBy(xScale: CGFloat, yScale: CGFloat) {
        transform = transform.scaledBy(x: xScale, y: yScale)
    }
    
    func zoomIn(by zoomScaleFactor: CGFloat) {}
    func zoomOut(by zoomScaleFactor: CGFloat) {}
}
