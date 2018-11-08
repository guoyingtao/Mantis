//
//  FixedRatios.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

class FixedRatioManager {
    private (set) var ratios: [RatioItemType] = []

    init(originalRatio: Double) {
        let original = ("Original", originalRatio, "Original", originalRatio)
        addDefault()
        insertToHead(ratioItem: original)
    }
    
    private func addDefault() {
        let square = ("Square", 1.0, "Square", 1.0)
        let scale3_2 = ("3:2", 3.0/2.0, "2:3", 2.0/3.0)
        let scale5_3 = ("5:3", 5.0/3.0, "3:5", 3.0/5.0)
        let scale4_3 = ("4:3", 4.0/3.0, "3:4", 3.0/4.0)
        let scale5_4 = ("5:4", 5.0/4.0, "4:5", 4.0/5.0)
        let scale7_5 = ("7:5", 7.0/5.0, "5:7", 5.0/7.0)
        let scale16_9 = ("16:9", 16.0/9.0, "9:16", 9.0/16.0)
        
        ratios.append(square)
        ratios.append(scale3_2)
        ratios.append(scale5_3)
        ratios.append(scale4_3)
        ratios.append(scale5_4)
        ratios.append(scale7_5)
        ratios.append(scale16_9)
    }
    
    func insertToHead(ratioItem: RatioItemType) {
        ratios.insert(ratioItem, at: 0)
    }
    
    func appendToTail(ratioItem: RatioItemType) {
        ratios.append(ratioItem)
    }

    func appendToTail(ratioItems: [RatioItemType]) {
        ratios.append(contentsOf: ratioItems)
    }
}
