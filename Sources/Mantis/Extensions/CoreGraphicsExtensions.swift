//
//  CoreGraphicsExtensions.swift
//  SwiftClock
//
//  Created by Joseph Daniels on 01/09/16.
//  Copyright © 2016 Joseph Daniels. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import UIKit

extension UIColor {
    var greyscale: UIColor{
        var (hue, saturation, brightness, alpha) = (CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0))

        if self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return  UIColor(hue: hue, saturation: 0, brightness: brightness, alpha: alpha / 2)
        }else {
            return UIColor.gray
        }
    }
    func modified(withAdditionalHue hue: CGFloat, additionalSaturation: CGFloat, additionalBrightness: CGFloat) -> UIColor {
        
        var currentHue: CGFloat = 0.0
        var currentSaturation: CGFloat = 0.0
        var currentBrigthness: CGFloat = 0.0
        var currentAlpha: CGFloat = 0.0
        
        if self.getHue(&currentHue, saturation: &currentSaturation, brightness: &currentBrigthness, alpha: &currentAlpha){
            return UIColor(hue: currentHue + hue,
                           saturation: currentSaturation + additionalSaturation,
                           brightness: currentBrigthness + additionalBrightness,
                           alpha: currentAlpha)
        } else {
            return self
        }
    }
}

extension Angle{
    var reverse:Angle{return 2 * CGFloat.pi - self}
}
extension FloatingPoint{
    var isBad:Bool{ return isNaN || isInfinite }
    var checked:Self{
        guard !isBad && !isInfinite else {
            fatalError("bad number!")
        }
        return self
    }

}

typealias Angle = CGFloat
func df() -> CGFloat {
    return    CGFloat(drand48()).checked
}

func clockDescretization(_ val: CGFloat) -> CGFloat{
    let min:Double  = 0
    let max:Double = 2 * Double.pi
    let steps:Double = 144
    let stepSize = (max - min) / steps
    let nsf = floor(Double(val) / stepSize)
    let rest = Double(val) - stepSize * nsf
    return CGFloat(rest > stepSize / 2 ? stepSize * (nsf + 1) : stepSize * nsf).checked
    
}

extension CALayer {
    func doDebug(){
        self.borderColor = UIColor(hue: df() , saturation: df(), brightness: 1, alpha: 1).cgColor
        self.borderWidth = 2;
        self.sublayers?.forEach({$0.doDebug()})
    }
}

extension CGSize{
    var hasNaN:Bool{return width.isBad || height.isBad }
    var checked:CGSize{
        guard !hasNaN else {
            fatalError("bad number!")
        }
        return self
    }
}

extension CGRect{
    var center:CGPoint { return CGPoint(x:midX, y: midY).checked}
    var hasNaN:Bool{return size.hasNaN || origin.hasNaN}
    var checked:CGRect{
        guard !hasNaN else {
            fatalError("bad number!")
        }
        return self
    }
}

extension CGPoint{
    var vector:CGVector { return CGVector(dx: x, dy: y).checked}
    var checked:CGPoint{
        guard !hasNaN else {
            fatalError("bad number!")
        }
        return self
    }
    var hasNaN:Bool{return x.isBad || y.isBad }
}

extension CGVector{
    var hasNaN:Bool{return dx.isBad || dy.isBad}
    var checked:CGVector{
        guard !hasNaN else {
            fatalError("bad number!")
        }
        return self
    }

    static var root:CGVector{ return CGVector(dx:1, dy:0).checked}
    var magnitude:CGFloat { return sqrt(pow(dx, 2) + pow(dy,2)).checked}
    var normalized: CGVector { return CGVector(dx:dx / magnitude,  dy: dy / magnitude).checked }
    var point:CGPoint { return CGPoint(x: dx, y: dy).checked}
    func rotate(_ angle:Angle) -> CGVector { return CGVector(dx: dx * cos(angle) - dy * sin(angle), dy: dx * sin(angle) + dy * cos(angle) ).checked}
    
    func dot(_ vec2:CGVector) -> CGFloat { return (dx * vec2.dx + dy * vec2.dy).checked}
    func add(_ vec2:CGVector) -> CGVector { return CGVector(dx:dx + vec2.dx , dy: dy + vec2.dy).checked}
    func cross(_ vec2:CGVector) -> CGFloat { return (dx * vec2.dy - dy * vec2.dx).checked}
    func scale(_ c:CGFloat) -> CGVector { return CGVector(dx:dx * c , dy: dy * c).checked}
    
    init( from:CGPoint, to:CGPoint){
        guard !from.hasNaN && !to.hasNaN  else {
                fatalError("Nan point!")
            }
        self.init()
        dx = to.x - from.x
        dy = to.y - from.y
        _ = self.checked
    }
    
    init(angle:Angle){
        let compAngle = angle < 0 ? (angle + 2 * CGFloat.pi) : angle
        self.init()
        dx = cos(compAngle.checked)
        dy = sin(compAngle.checked)
        _ = self.checked
    }
    
    var theta:Angle{
        return atan2(dy, dx)}
    
    static func theta(_ vec1:CGVector, vec2:CGVector) -> Angle{
		var i = vec1.normalized.dot(vec2.normalized)
        if (i > 1) {
    		i = 1;
        }
        if (i < -1){
         	i = -1;
        }
        return acos(i).checked
    }
    
    static func signedTheta(_ vec1:CGVector, vec2:CGVector) -> Angle{
        
        return (vec1.normalized.cross(vec2.normalized) > 0 ?  -1 : 1) * theta(vec1.normalized, vec2: vec2.normalized).checked
    }
}
