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

typealias RadiansAngle = CGFloat

extension FloatingPoint {
    var isBad: Bool { return isNaN || isInfinite }
    var checked: Self {
        guard !isBad && !isInfinite else {
            fatalError("bad number!")
        }
        return self
    }
}

extension CGSize {
    var hasNaN: Bool {return width.isBad || height.isBad }
    var checked: CGSize {
        guard !hasNaN else {
            fatalError("bad number!")
        }
        return self
    }
}

extension CGRect {
    var center: CGPoint { return CGPoint(x: midX, y: midY).checked }
    var hasNaN: Bool {return size.hasNaN || origin.hasNaN}
    var checked: CGRect {
        guard !hasNaN else {
            fatalError("bad number!")
        }
        return self
    }
}

extension CGPoint {
    var vector: CGVector { return CGVector(dx: x, dy: y).checked }
    var checked: CGPoint {
        guard !hasNaN else {
            fatalError("bad number!")
        }
        return self
    }
    var hasNaN: Bool {return x.isBad || y.isBad }
}

extension CGVector {
    var hasNaN: Bool { return dx.isBad || dy.isBad }
    var checked: CGVector {
        guard !hasNaN else {
            fatalError("bad number!")
        }
        return self
    }
    
    static var root: CGVector { return CGVector(dx: 1, dy: 0).checked }
    var magnitude: CGFloat { return sqrt(pow(dx, 2) + pow(dy, 2)).checked }
    var normalized: CGVector { return CGVector(dx: dx / magnitude, dy: dy / magnitude).checked }
    var point: CGPoint { return CGPoint(x: dx, y: dy).checked }
    func rotate(_ angle: RadiansAngle) -> CGVector { return CGVector(dx: dx * cos(angle) - dy * sin(angle), dy: dx * sin(angle) + dy * cos(angle) ).checked}
    
    func dot(_ vec2: CGVector) -> CGFloat { return (dx * vec2.dx + dy * vec2.dy).checked}
    func add(_ vec2: CGVector) -> CGVector { return CGVector(dx: dx + vec2.dx, dy: dy + vec2.dy).checked}
    func cross(_ vec2: CGVector) -> CGFloat { return (dx * vec2.dy - dy * vec2.dx).checked}
    func scale(_ scale: CGFloat) -> CGVector { return CGVector(dx: dx * scale, dy: dy * scale).checked}
    
    init(fromPoint: CGPoint, toPoint: CGPoint) {
        guard !fromPoint.hasNaN && !toPoint.hasNaN  else {
            fatalError("Nan point!")
        }
        self.init()
        dx = toPoint.x - fromPoint.x
        dy = toPoint.y - fromPoint.y
        _ = self.checked
    }
    
    init(angle: RadiansAngle) {
        let compAngle = angle < 0 ? (angle + 2 * CGFloat.pi) : angle
        self.init()
        dx = cos(compAngle.checked)
        dy = sin(compAngle.checked)
        _ = self.checked
    }
    
    var theta: RadiansAngle {
        return atan2(dy, dx)}
    
    static func theta(_ vec1: CGVector, vec2: CGVector) -> RadiansAngle {
        var result = vec1.normalized.dot(vec2.normalized)
        if result > 1 {
            result = 1
        } else if result < -1 {
            result = -1
        }
        return acos(result).checked
    }
    
    static func signedTheta(_ vec1: CGVector, vec2: CGVector) -> RadiansAngle {
        
        return (vec1.normalized.cross(vec2.normalized) > 0 ?  -1 : 1) * theta(vec1.normalized, vec2: vec2.normalized).checked
    }
}
