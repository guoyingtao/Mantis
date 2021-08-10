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
        localizationConfig: LocalizationConfig,
        key: String,
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
