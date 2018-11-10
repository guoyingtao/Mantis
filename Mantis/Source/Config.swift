//
//  Config.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

public class Config {
    var customRatios: [(width: Int, height: Int)] = []
    
    public static var shared = Config()
    
    private init() {}

    func hasCustomRatios() -> Bool {
        return customRatios.count > 0
    }
    
    public func addCustomRatio(byWidth width: Int, andHeight height: Int) {
        customRatios.append((width, height))
    }
}
