//
//  TestHelper.swift
//  Mantis
//
//  Created by yingtguo on 2/3/23.
//

import UIKit

class TestHelper {
    static func createATestImage(bySize size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { rendererContext in
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
