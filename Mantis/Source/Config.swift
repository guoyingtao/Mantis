//
//  Config.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

public typealias RatioItemType = (nameH: String, ratioH: Double, nameV: String, ratioV: Double)

public class Config {
    public var customRatios: [RatioItemType] = []
    
    public static var shared = Config()
    
    private init() {}

    public func addCustomRatio(ratioItem: RatioItemType) {
        customRatios.append(ratioItem)
    }
}
