//
//  LocalizedHelper.swift
//  Mantis
//
//  Created by Echo on 11/13/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import Foundation

struct LocalizedHelper {
    static func getString(
        _ key: String,
        localizationConfig: LocalizationConfig = Mantis.localizationConfig,
        value: String? = nil
    ) -> String {
        let value = value ?? key
        let bundle = localizationConfig.bundle ?? Bundle.module

        guard let bundle = convertToLanguageBundleIfNeeded(by: bundle) else {
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
    
    static private func convertToLanguageBundleIfNeeded(by bundle: Bundle?) -> Bundle? {
        if let languageCode = Mantis.Config.language?.code,
           let languageBundlePath = bundle?.path(forResource: languageCode, ofType: "lproj"),
           let languageBundle = Bundle(path: languageBundlePath) {
            return languageBundle
        }
        
        return bundle
    }
}
