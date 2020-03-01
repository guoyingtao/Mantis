//
//  LocalizedHelper.swift
//  Mantis
//
//  Created by Echo on 11/13/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

struct LocalizedHelper {
    static func getString(_ key: String, value: String? = nil, comment: String = "") -> String {
        let value = value ?? key
        
        var text = value
        if let bundle = Mantis.bundle {            
            text = NSLocalizedString(key, tableName: "MantisLocalizable", bundle: bundle, value: value, comment: comment)
        }
        return text
    }
}
