//
//  XMCircleGestureRecognizer.swift
//  XMCircleGestureRecognizer
//
//  Created by Michael Teeuw on 20-06-14.
//  https://github.com/MichMich/XMCircleGestureRecognizer
//  Modified by Yingtao Guo on 10/21/18 (Adapted to the newest swift)
//  Copyright (c) 2014 Michael Teeuw. All rights reserved.
//
import UIKit
import UIKit.UIGestureRecognizerSubclass

let π = CGFloat(Double.pi)

extension CGFloat {
    var degrees:CGFloat {
        return self * 180 / π;
    }
    var radians:CGFloat {
        return self * π / 180;
    }
    var rad2deg:CGFloat {
        return self.degrees
    }
    var deg2rad:CGFloat {
        return self.radians
    }
    
}

class XMCircleGestureRecognizer: UIGestureRecognizer {
    
    // midpoint for gesture recognizer
    var midPoint = CGPoint.zero
    
    // minimal distance from midpoint
    var innerRadius:CGFloat?
    
    // maximal distance to midpoint
    var outerRadius:CGFloat?
    
    // relative rotation for current gesture (in radians)
    var rotation:CGFloat? {
        if let currentPoint = self.currentPoint {
            if let previousPoint = self.previousPoint {
                var rotation = angleBetween(pointA: currentPoint, andPointB: previousPoint)
                
                if (rotation > π) {
                    rotation -= π*2
                } else if (rotation < -π) {
                    rotation += π*2
                }
                
                return rotation
            }
        }
        
        return nil
    }
    
    // absolute angle for current gesture (in radians)
    var angle:CGFloat? {
        if let nowPoint = self.currentPoint {
            return self.angleForPoint(point: nowPoint)
        }
        
        return nil
    }
    
    // distance from midpoint
    var distance:CGFloat? {
        if let nowPoint = self.currentPoint {
            return self.distanceBetween(pointA: self.midPoint, andPointB: nowPoint)
        }
        
        return nil
    }
    
    private var currentPoint:CGPoint?
    private var previousPoint:CGPoint?
    
    // designated initializer
    init(midPoint:CGPoint, innerRadius:CGFloat?, outerRadius:CGFloat?, target:AnyObject?, action:Selector) {
        super.init(target: target, action: action)
        
        self.midPoint = midPoint
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
    }
    
    // convinience initializer if innerRadius and OuterRadius are not necessary
    convenience init(midPoint:CGPoint, target:AnyObject?, action:Selector) {
        self.init(midPoint:midPoint, innerRadius:nil, outerRadius:nil, target:target, action:action)
    }
    
    private func distanceBetween(pointA:CGPoint, andPointB pointB:CGPoint) -> CGFloat {
        let dx = Float(pointA.x - pointB.x)
        let dy = Float(pointA.y - pointB.y)
        return CGFloat(sqrtf(dx*dx + dy*dy))
    }
    
    private func angleForPoint(point:CGPoint) -> CGFloat {
        var angle = CGFloat(-atan2f(Float(point.x - midPoint.x), Float(point.y - midPoint.y))) + π/2
        
        
        if (angle < 0) {
            angle += π*2;
        }
        
        
        return angle
    }
    
    private func angleBetween(pointA:CGPoint, andPointB pointB:CGPoint) -> CGFloat {
        return angleForPoint(point: pointA) - angleForPoint(point: pointB)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        if let firstTouch = touches.first {
            
            currentPoint = firstTouch.location(in: self.view)
            
            var newState:UIGestureRecognizer.State = .began
            
            if let innerRadius = self.innerRadius, let distance = self.distance {
                if distance < innerRadius {
                    newState = .failed
                }
            }
            
            if let outerRadius = self.outerRadius, let distance = self.distance {
                if distance > outerRadius {
                    newState = .failed
                }
            }
            
            state = newState
            
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        
        super.touchesMoved(touches, with: event)
        
        if state == .failed {
            return
        }
        
        if let firstTouch = touches.first {
            
            currentPoint = firstTouch.location(in: self.view)
            previousPoint = firstTouch.previousLocation(in: self.view)
            
            state = .changed
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        state = .ended
        
        currentPoint = nil
        previousPoint = nil
    }
}
