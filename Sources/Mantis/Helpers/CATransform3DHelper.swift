import Foundation
import UIKit

class CATransform3DHelper {
    func rectToQuad(_ rect: CGRect,
                    _ topLeft: CGPoint, _ topRight: CGPoint, _ bottomLeft: CGPoint, _ bottomRight: CGPoint) -> CATransform3D {
        rectToQuadCalculation(rect,
                              topLeft.x, topLeft.y,
                              topRight.x, topRight.y,
                              bottomLeft.x, bottomLeft.y,
                              bottomRight.x, bottomRight.y)
    }
    
    func rectToQuadCalculation(_ rect: CGRect,
                               _ x1a: CGFloat, _ y1a: CGFloat,
                               _ x2a: CGFloat, _ y2a: CGFloat,
                               _ x3a: CGFloat, _ y3a: CGFloat,
                               _ x4a: CGFloat, _ y4a: CGFloat) -> CATransform3D {
        let XX = rect.origin.x
        let YY = rect.origin.y
        let WW = rect.size.width
        let HH = rect.size.height
        
        let y21 = y2a - y1a
        let y32 = y3a - y2a
        let y43 = y4a - y3a
        let y14 = y1a - y4a
        let y31 = y3a - y1a
        let y42 = y4a - y2a
        
        let a = -HH * (x2a*x3a*y14 + x2a*x4a*y31 - x1a*x4a*y32 + x1a*x3a*y42)
        let b = WW * (x2a*x3a*y14 + x3a*x4a*y21 + x1a*x4a*y32 + x1a*x2a*y43)
        
        let c0 = -HH * WW * x1a * (x4a*y32 - x3a*y42 + x2a*y43)
        let cx = HH * XX * (x2a*x3a*y14 + x2a*x4a*y31 - x1a*x4a*y32 + x1a*x3a*y42)
        let cy = -WW * YY * (x2a*x3a*y14 + x3a*x4a*y21 + x1a*x4a*y32 + x1a*x2a*y43)
        let c = c0 + cx + cy
        let d = HH * (-x4a*y21*y3a + x2a*y1a*y43 - x1a*y2a*y43 - x3a*y1a*y4a + x3a*y2a*y4a)
        let e = WW * (x4a*y2a*y31 - x3a*y1a*y42 - x2a*y31*y4a + x1a*y3a*y42)
        
        let f0 = -WW * HH * (x4a * y1a * y32 - x3a * y1a * y42 + x2a * y1a * y43)
        let fx = HH * XX * (x4a * y21 * y3a - x2a * y1a * y43 - x3a * y21 * y4a + x1a * y2a * y43)
        let fy = -WW * YY * (x4a * y2a * y31 - x3a * y1a * y42 - x2a * y31 * y4a + x1a * y3a * y42)
        let f = f0 + fx + fy
        let g = HH * (x3a * y21 - x4a * y21 + (-x1a + x2a) * y43)
        let h = WW * (-x2a * y31 + x4a * y31 + (x1a - x3a) * y42)
        
        let iy = WW * YY * (x2a * y31 - x4a * y31 - x1a * y42 + x3a * y42)
        let ix = HH * XX * (x4a * y21 - x3a * y21 + x1a * y43 - x2a * y43)
        let i0 = HH * WW * (x3a * y42 - x4a * y32 - x2a * y43)
        var i = i0 + ix + iy
        let kEpsilon: CGFloat = 0.0001
        if abs(i) < kEpsilon {
            i = kEpsilon * (i > 0 ? 1 : -1)
        }
        
        return CATransform3D(
            m11: a/i, m12: d/i, m13: 0, m14: g/i,
            m21: b/i, m22: e/i, m23: 0, m24: h/i,
            m31: 0, m32: 0, m33: 1, m34: 0,
            m41: c/i, m42: f/i, m43: 0, m44: 1.0)
    }
    
    func boundingBoxForQuadTR(_ tl: CGPoint, _ tr: CGPoint, _ bl: CGPoint, _ br: CGPoint) -> CGRect {
        var b: CGRect = .zero
        let xmin: CGFloat = min(min(min(tr.x,tl.x),bl.x),br.x)
        let ymin: CGFloat = min(min(min(tr.y,tl.y),bl.y),br.y)
        let xmax: CGFloat = max(max(max(tr.x,tl.x),bl.x),br.x)
        let ymax: CGFloat = max(max(max(tr.y,tl.y),bl.y),br.y)
        b.origin.x = xmin
        b.origin.y = ymin
        b.size.width = xmax - xmin
        b.size.height = ymax - ymin
        return b
    }
}

extension UIView {
    
    func transformToFitQuad(tl: CGPoint, tr: CGPoint, bl: CGPoint, br: CGPoint) {
        
        let transformHelper = CATransform3DHelper()
        
        //  To account for anchor point, we must translate, transform, translate
        let b = transformHelper.boundingBoxForQuadTR(tl, tr, bl, br)
        self.frame = b

        let anchorPoint = self.layer.position
        let anchorOffset = CGPoint(x: anchorPoint.x - b.origin.x, y: anchorPoint.y - b.origin.y)
        let transPos = CATransform3DMakeTranslation(anchorOffset.x, anchorOffset.y, 0.0)
        let transNeg = CATransform3DMakeTranslation(-anchorOffset.x, -anchorOffset.y, 0.0)
        let transform = transformHelper.rectToQuad(bounds,
                                                   .init(x: tl.x-b.origin.x, y: tl.y-b.origin.y),
                                                   .init(x: tr.x-b.origin.x, y: tr.y-b.origin.y),
                                                   .init(x: bl.x-b.origin.x, y: bl.y-b.origin.y),
                                                   .init(x: br.x-b.origin.x, y: br.y-b.origin.y))
        
        let fullTransform = CATransform3DConcat(CATransform3DConcat(transPos, transform), transNeg)
        
        self.layer.transform = fullTransform
    }
}

