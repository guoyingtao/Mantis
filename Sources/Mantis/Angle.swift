//
//  Angle.swift
//  Mantis
//
//  Created by Echo on 5/22/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import UIKit

/// Use this class to make angle calculation to be simpler
public final class Angle: NSObject, Comparable {
    public static func < (lhs: Angle, rhs: Angle) -> Bool {
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
    
    static public func + (lhs: Angle, rhs: Angle) -> Angle {
        return Angle(radians: lhs.radians + rhs.radians)
    }
    
    static public func += (lhs: inout Angle, rhs: Angle) {
        lhs = Angle(radians: lhs.radians + rhs.radians)
    }
    
    static public func * (lhs: Angle, rhs: Angle) -> Angle {
        return Angle(radians: lhs.radians * rhs.radians)
    }
    
    static public func - (lhs: Angle, rhs: Angle) -> Angle {
        return Angle(radians: lhs.radians - rhs.radians)
    }
    
    static public func -= (lhs: inout Angle, rhs: Angle) {
        lhs = Angle(radians: lhs.radians - rhs.radians)
    }
    
    static public prefix func - (rhs: Angle) -> Angle {
        return Angle(radians: -rhs.radians)
    }

    static public func / (lhs: Angle, rhs: Angle) -> Angle {
        guard rhs.radians != 0 else {
            if lhs.radians == 0 { return Angle(radians: 0)}
            if lhs.radians > 0 { return Angle(radians: CGFloat.infinity)}
            return Angle(radians: -CGFloat.infinity)
        }
        return Angle(radians: lhs.radians / rhs.radians)
    }
}
