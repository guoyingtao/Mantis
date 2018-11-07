//
//  FixedRatios.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

enum RatioType {
    case horizontal
    case vertical
}

struct RatioData: ExpressibleByStringLiteral, Equatable {
    typealias StringLiteralType = String
    
    var textForHoritontal: String = ""
    var textForVertical: String = ""
    var ratioForHoritontal: Double = 1.0
    var ratioForVertical: Double = 1.0
    
    init(stringLiteral value: RatioData.StringLiteralType) {
        textForHoritontal = value
        
        let components = textForHoritontal.components(separatedBy: ":")
        if components.count == 2 {
            textForVertical = components[1] + ":" + components[0]
            
            guard let v0 = Double(components[0]), let v1 = Double(components[1]), v0 != 0, v1 != 0 else {
                return
            }
            
            ratioForHoritontal = v0 / v1
            ratioForVertical = v1 / v0
        } else {
            textForVertical = textForHoritontal
        }
                
        guard ratioForHoritontal != 0 else { return }
        ratioForVertical = 1.0 / ratioForHoritontal
    }
    
    func getText(by ratioType: RatioType) -> String {
        return ratioType == .horizontal ? textForHoritontal : textForVertical
    }
    
    func getRatio(by ratioType: RatioType) -> Double {
        return ratioType == .horizontal ? ratioForHoritontal : ratioForVertical
    }
}

enum FixedRatiosType: RatioData, CaseIterable {
    case original = "Original"
    case square = "Square"
    case scale3_2 = "3:2"
    case scale5_3 = "5:3"
    case scale4_3 = "4:3"
    case scale5_4 = "5:4"
    case scale7_5 = "7:5"
    case scale16_9 = "16:9"

    func getText(by ratioType: RatioType) -> String {
        return self.rawValue.getText(by: ratioType)
    }
    
    func getRatio(by ratioType: RatioType) -> Double {
        return self.rawValue.getRatio(by: ratioType)
    }
}
