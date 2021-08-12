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

        guard let bundle = localizationConfig.bundle ?? Mantis.bundle else {
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
