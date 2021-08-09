//
//  LocalizedHelper.swift
//  Mantis
//
//  Created by Echo on 11/13/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

struct LocalizedHelper {
    private static var bundle: Bundle?
    
    static func setBundle(_ bundle: Bundle) {
        guard let resourceBundleURL = bundle.url(
            forResource: "MantisResource", withExtension: "bundle")
            else { return }
        LocalizedHelper.bundle = Bundle(url: resourceBundleURL)
    }
    
    static func getString(_ key: String, value: String? = nil, comment: String = "") -> String {
        let value = value ?? key
        var text = value
        
        if let bundle = LocalizedHelper.bundle {
            text = NSLocalizedString(key,
                                     tableName: "MantisLocalizable",
                                     bundle: bundle,
                                     value: value,
                                     comment: comment)
        } else if let bundle = Mantis.bundle {
            text = NSLocalizedString(key,
                                     tableName: "MantisLocalizable",
                                     bundle: bundle,
                                     value: value,
                                     comment: comment)
        }
                
        return text
    }
}
