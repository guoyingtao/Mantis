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
    
    static func getString(
        _ key: String,
        localizationConfig: LocalizationConfig = Mantis.localizationConfig,
        value: String? = nil
    ) -> String {
        let value = value ?? key

        guard let bundle = LocalizedHelper.bundle ?? (localizationConfig.bundle ?? Mantis.bundle) else {
            return value
        }

        return NSLocalizedString(
            key,
            tableName: localizationConfig.tableName,
            bundle: bundle,
            value: value,
            comment: ""
        )
    }
}
