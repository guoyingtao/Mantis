//
//  Config.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

public class MantisConfig {
    var customRatios: [(width: Int, height: Int)] = []
    
    public init() {
    }
    
    public func addCustomRatio(byWidth width: Int, andHeight height: Int) {
        customRatios.append((width, height))
    }
    
    func hasCustomRatios() -> Bool {
        return customRatios.count > 0
    }
        
    func getCustomRatioItems() -> [RatioItemType] {
        return customRatios.map {
            (String("\($0.width):\($0.height)"), Double($0.width)/Double($0.height), String("\($0.height):\($0.width)"), Double($0.height)/Double($0.width))
        }
    }
}
