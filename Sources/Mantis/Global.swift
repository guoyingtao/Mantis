//
//  Global.swift
//  Mantis
//
//  Created by yingtguo on 7/17/22.
//

import Foundation

func print(_ objects: Any...) {
    #if DEBUG
    for item in objects {
        Swift.print(item)
    }
    #endif
}

func print(_ object: Any) {
    #if DEBUG
    Swift.print(object)
    #endif
}
