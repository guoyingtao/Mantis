//
//  FixedRatioManager.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

typealias RatioItemType = (nameH: String, ratioH: Double, nameV: String, ratioV: Double)

class FixedRatioManager {
    private (set) var ratios: [RatioItemType] = []
    private var ratioOptions: RatioOptions = .all
    private var customRatios: [RatioItemType] = []
    
    var type: RatioType = .horizontal
    var originalRatioH = 1.0

    init(type: RatioType, originalRatioH: Double, ratioOptions: RatioOptions = .all, customRatios: [RatioItemType] = []) {

        self.type = type
        self.originalRatioH = originalRatioH
        
        if ratioOptions.contains(.original) {
            appendToTail(ratioItem: getOriginalRatioItem())
        }
        
        if ratioOptions.contains(.square) {
            let squareText = LocalizedHelper.getString("Square")
            let square = (squareText, 1.0, squareText, 1.0)
            appendToTail(ratioItem: square)
        }

        if ratioOptions.contains(.extraDefaultRatios) {
            addExtraDefaultRatios()
        }
        
        if ratioOptions.contains(.custom) {
            appendToTail(ratioItems: customRatios)
        }
        
        sort(isByHorizontal: (type == .horizontal))
    }
    
    func getOriginalRatioItem() -> RatioItemType {
        let originalText = LocalizedHelper.getString("Original")
        return (originalText, originalRatioH, originalText, originalRatioH)
    }
}

// MARK: - Private methods
extension FixedRatioManager {
    private func addExtraDefaultRatios() {
        let scale3_2 = RatioItemType("3:2", 3.0/2.0, "2:3", 2.0/3.0)
        let scale5_3 = RatioItemType("5:3", 5.0/3.0, "3:5", 3.0/5.0)
        let scale4_3 = RatioItemType("4:3", 4.0/3.0, "3:4", 3.0/4.0)
        let scale5_4 = RatioItemType("5:4", 5.0/4.0, "4:5", 4.0/5.0)
        let scale7_5 = RatioItemType("7:5", 7.0/5.0, "5:7", 5.0/7.0)
        let scale16_9 = RatioItemType("16:9", 16.0/9.0, "9:16", 9.0/16.0)
        
        appendToTail(ratioItem: scale3_2)
        appendToTail(ratioItem: scale5_3)
        appendToTail(ratioItem: scale4_3)
        appendToTail(ratioItem: scale5_4)
        appendToTail(ratioItem: scale7_5)
        appendToTail(ratioItem: scale16_9)
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
    
    private func insertToHead(ratioItem: RatioItemType) {
        guard contains(ratioItem: ratioItem) == false else { return }
        ratios.insert(ratioItem, at: 0)
    }
    
    private func appendToTail(ratioItem: RatioItemType) {
        guard contains(ratioItem: ratioItem) == false else { return }
        ratios.append(ratioItem)
    }
    
    private func appendToTail(ratioItems: [RatioItemType]) {
        ratioItems.forEach{
            appendToTail(ratioItem: $0)
        }
    }
    
    private func appendToTail(items: [(width: Int, height: Int)]) {
        items.forEach {
            let ratioItem = (String("\($0.width):\($0.height)"), Double($0.width)/Double($0.height), String("\($0.height):\($0.width)"), Double($0.height)/Double($0.width))
            appendToTail(ratioItem: ratioItem)
        }
    }
    
    private func sort(isByHorizontal: Bool) {
        guard ratios.count > 1 else {
            return
        }
        
        if isByHorizontal {
            ratios = ratios[...1] + ratios[2...].sorted { getHeight(fromNameH: $0.nameH) < getHeight(fromNameH: $1.nameH) }
        } else {
            ratios = ratios[...1] + ratios[2...].sorted { getWidth(fromNameH: $0.nameH) < getWidth(fromNameH: $1.nameH) }
        }
    }
}
