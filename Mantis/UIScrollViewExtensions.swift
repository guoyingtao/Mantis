//
//  UIScrollViewExtensions.swift
//  Mantis
//
//  Created by Echo on 10/25/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

// https://timoliver.blog/2015/03/31/zoom-to-a-point-in-a-uiscrollview-2015-edition/
extension UIScrollView {
    
    func zoomTo(zoomPoint: CGPoint, withScale scale: CGFloat, animated: Bool) {
        var scale = scale
        //Ensure scale is clamped to the scroll view's allowed zooming range
        scale = min(scale, maximumZoomScale)
        scale = max(scale, minimumZoomScale)
        
        //`zoomToRect` works on the assumption that the input frame is in relation
        //to the content view when zoomScale is 1.0
        
        //Work out in the current zoomScale, where on the contentView we are zooming
        var translatedZoomPoint = CGPoint.zero
        translatedZoomPoint.x = zoomPoint.x + contentOffset.x
        translatedZoomPoint.y = zoomPoint.y + contentOffset.y
        
        //Figure out what zoom scale we need to get back to default 1.0f
        let zoomFactor = 1.0 / zoomScale
        
        //By multiplying by the zoom factor, we get where we're zooming to, at scale 1.0f;
        translatedZoomPoint.x *= zoomFactor
        translatedZoomPoint.y *= zoomFactor
        
        //work out the size of the rect to zoom to, and place it with the zoom point in the middle
        var destinationRect = CGRect.zero;
        destinationRect.size.width = frame.width / scale
        destinationRect.size.height = frame.height / scale
        destinationRect.origin.x = translatedZoomPoint.x - destinationRect.width * 0.5
        destinationRect.origin.y = translatedZoomPoint.y - destinationRect.height * 0.5
        
        if (animated) {
            UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.6, options: [.allowUserInteraction], animations: {
                self.zoom(to: destinationRect, animated: false)
            }) { _ in
                guard let view = self.delegate?.viewForZooming?(in: self) else {
                    return
                }
                self.delegate?.scrollViewDidEndZooming?(self, with: view, atScale: scale)
            }
        }
        else {
            self.zoom(to: destinationRect, animated: false)
        }
    }
}

extension CGAffineTransform {
    var angle: CGFloat { return atan2(-self.c, self.a) }
    
    var angleInDegrees: CGFloat { return self.angle * 180 / .pi }
    
    var scaleX: CGFloat {
        let angle = self.angle
        return self.a * cos(angle) - self.c * sin(angle)
    }
    
    var scaleY: CGFloat {
        let angle = self.angle
        return self.d * cos(angle) + self.b * sin(angle)
    }
}
