//
//  CGAngle.swift
//  Puffer
//
//  Created by Echo on 5/22/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import UIKit

/// Use this class to make angle calculation to be simpler
public class CGAngle: NSObject, Comparable {
    public static func < (lhs: CGAngle, rhs: CGAngle) -> Bool {
        return lhs.radians < rhs.radians
    }
    
    public var radians: CGFloat = 0.0
    
    @inlinable public var degrees: CGFloat {
        get {
            return radians / CGFloat.pi * 180.0
        }
        set {
            radians = newValue / 180.0 * CGFloat.pi
        }
    }

    public init(radians: CGFloat) {
        self.radians = radians
    }

    public init(degrees: CGFloat) {
        self.radians = degrees / 180.0 * CGFloat.pi
    }

    override public var description: String {
        return String(format: "%0.2f°", degrees)
    }
    
    static public func + (lhs: CGAngle, rhs: CGAngle) -> CGAngle {
        return CGAngle(radians: lhs.radians + rhs.radians)
    }
    
    static public func * (lhs: CGAngle, rhs: CGAngle) -> CGAngle {
        return CGAngle(radians: lhs.radians * rhs.radians)
    }
    
    static public func - (lhs: CGAngle, rhs: CGAngle) -> CGAngle {
        return CGAngle(radians: lhs.radians - rhs.radians)
    }
    
    static public prefix func - (rhs: CGAngle) -> CGAngle {
        return CGAngle(radians: -rhs.radians)
    }

    static public func / (lhs: CGAngle, rhs: CGAngle) -> CGAngle {
        guard rhs.radians != 0 else {
            if lhs.radians == 0 { return CGAngle(radians: 0)}
            if lhs.radians > 0 { return CGAngle(radians: CGFloat.infinity)}
            return CGAngle(radians: -CGFloat.infinity)
        }
        return CGAngle(radians: lhs.radians / rhs.radians)
    }

}
