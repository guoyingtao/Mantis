//
//  RatioOptions.swift
//  Mantis
//
//  Created by Echo on 8/8/19.
//

import Foundation

public struct RatioOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    static public let original = RatioOptions(rawValue: 1 << 0)
    static public let defaultExtraRatios = RatioOptions(rawValue: 1 << 1)
    static public let custom = RatioOptions(rawValue: 1 << 2)
    
    static public let all: RatioOptions = [original, defaultExtraRatios, custom]
}
