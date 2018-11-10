//
//  FixedRatios.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

typealias RatioItemType = (nameH: String, ratioH: Double, nameV: String, ratioV: Double)

class FixedRatioManager {
    private (set) var ratios: [RatioItemType] = []

    init(originalRatioH: Double) {
        let original = ("Original", originalRatioH, "Original", originalRatioH)
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
    
    private func contains(ratioItem: RatioItemType) -> Bool {
        var contains = false
        ratios.forEach {
            if ($0.nameH == ratioItem.nameH || $0.nameV == ratioItem.nameV) {
                contains = true
            }
        }
        return contains
    }
    
    func insertToHead(ratioItem: RatioItemType) {
        guard contains(ratioItem: ratioItem) == false else { return }
        ratios.insert(ratioItem, at: 0)
    }
    
    func appendToTail(ratioItem: RatioItemType) {
        guard contains(ratioItem: ratioItem) == false else { return }
        ratios.append(ratioItem)
    }

    func appendToTail(ratioItems: [RatioItemType]) {
        ratioItems.forEach{
            appendToTail(ratioItem: $0)
        }
    }
    
    func appendToTail(items: [(width: Int, height: Int)]) {
        items.forEach {
            let ratioItem = (String("\($0.width):\($0.height)"), Double($0.width)/Double($0.height), String("\($0.height):\($0.width)"), Double($0.height)/Double($0.width))
            appendToTail(ratioItem: ratioItem)
        }
    }
    
    func sort(isByHorizontal: Bool) {
        if isByHorizontal {
            ratios = ratios[...1] + ratios[2...].sorted { getHeight(fromNameH: $0.nameH) < getHeight(fromNameH: $1.nameH) }
        } else {
            ratios = ratios[...1] + ratios[2...].sorted { getWidth(fromNameH: $0.nameH) < getWidth(fromNameH: $1.nameH) }
        }
    }
    
    private func getWidth(fromNameH nameH: String) -> Int {
        let items = nameH.split(separator: ":")
        guard items.count == 2 else {
            return 0
        }
        
        guard let width = Int(items[0]) else {
            return 0
        }
        
        return width
    }
    
    private func getHeight(fromNameH nameH: String) -> Int {
        let items = nameH.split(separator: ":")
        guard items.count == 2 else {
            return 0
        }
        
        guard let width = Int(items[1]) else {
            return 0
        }
        
        return width
    }
}
