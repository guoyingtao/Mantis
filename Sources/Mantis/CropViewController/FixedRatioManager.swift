//
//  FixedRatioManager.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

struct RatioItemType {
    var nameH: String
    var ratioH: Double
    var nameV: String
    var ratioV: Double
    
    init?(nameH: String, ratioH: Double, nameV: String, ratioV: Double) {
        guard ratioH > 0 && ratioV > 0 else {
            return nil
        }
        
        self.nameH = nameH
        self.ratioH = ratioH
        self.nameV = nameV
        self.ratioV = ratioV
    }
}

class FixedRatioManager {
    private (set) var ratios: [RatioItemType] = []
    private var ratioOptions: RatioOptions = .all
    private var customRatios: [RatioItemType] = []

    var type: RatioType = .horizontal
    var originalRatioH = 1.0
    let fixedRatioNumber = 2

    init(type: RatioType, originalRatioH: Double, ratioOptions: RatioOptions = .all, customRatios: [RatioItemType] = []) {

        self.type = type
        self.originalRatioH = originalRatioH

        if ratioOptions.contains(.original) {
            appendToTail(ratioItem: getOriginalRatioItem())
        }

        if ratioOptions.contains(.square) {
            let squareText = LocalizedHelper.getString("Mantis.Square", value: "Square")
            let square = RatioItemType(nameH: squareText, ratioH: 1.0, nameV: squareText, ratioV: 1.0)
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

    func getOriginalRatioItem() -> RatioItemType? {
        let originalText = LocalizedHelper.getString("Mantis.Original", value: "Original")
        return RatioItemType(nameH: originalText, ratioH: originalRatioH, nameV: originalText, ratioV: originalRatioH)
    }
}

// MARK: - Private methods
extension FixedRatioManager {
    private func addExtraDefaultRatios() {
        let scale3to2 = RatioItemType(nameH: "3:2", ratioH: 3.0/2.0, nameV: "2:3", ratioV: 2.0/3.0)
        let scale5to3 = RatioItemType(nameH: "5:3", ratioH: 5.0/3.0, nameV: "3:5", ratioV: 3.0/5.0)
        let scale4to3 = RatioItemType(nameH: "4:3", ratioH: 4.0/3.0, nameV: "3:4", ratioV: 3.0/4.0)
        let scale5to4 = RatioItemType(nameH: "5:4", ratioH: 5.0/4.0, nameV: "4:5", ratioV: 4.0/5.0)
        let scale7to5 = RatioItemType(nameH: "7:5", ratioH: 7.0/5.0, nameV: "5:7", ratioV: 5.0/7.0)
        let scale16to9 = RatioItemType(nameH: "16:9", ratioH: 16.0/9.0, nameV: "9:16", ratioV: 9.0/16.0)

        appendToTail(ratioItem: scale3to2)
        appendToTail(ratioItem: scale5to3)
        appendToTail(ratioItem: scale4to3)
        appendToTail(ratioItem: scale5to4)
        appendToTail(ratioItem: scale7to5)
        appendToTail(ratioItem: scale16to9)
    }

    private func contains(ratioItem: RatioItemType) -> Bool {
        var contains = false
        ratios.forEach {
            if $0.nameH == ratioItem.nameH || $0.nameV == ratioItem.nameV {
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

    private func appendToTail(ratioItem: RatioItemType?) {
        guard let ratioItem = ratioItem, contains(ratioItem: ratioItem) == false else { return }
        ratios.append(ratioItem)
    }

    private func appendToTail(ratioItems: [RatioItemType]) {
        ratioItems.forEach {
            appendToTail(ratioItem: $0)
        }
    }

    private func appendToTail(items: [(width: Int, height: Int)]) {
        items.forEach {
            let ratioItem = RatioItemType(nameH: String("\($0.width):\($0.height)"),
                                          ratioH: Double($0.width)/Double($0.height),
                                          nameV: String("\($0.height):\($0.width)"),
                                          ratioV: Double($0.height)/Double($0.width))
            appendToTail(ratioItem: ratioItem)
        }
    }

    private func sort(isByHorizontal: Bool) {
        guard ratios.count > fixedRatioNumber - 1 else {
            return
        }

        if isByHorizontal {
            ratios = ratios[...(fixedRatioNumber - 1)] + ratios[fixedRatioNumber...]
                .sorted { getHeight(fromNameH: $0.nameH) < getHeight(fromNameH: $1.nameH) }
        } else {
            ratios = ratios[...(fixedRatioNumber - 1)] + ratios[fixedRatioNumber...]
                .sorted { getWidth(fromNameH: $0.nameH) < getWidth(fromNameH: $1.nameH) }
        }
    }
}
