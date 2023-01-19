//
//  UIViewExtensions.swift
//  Mantis
//
//  Created by yingtguo on 1/19/23.
//

import UIKit

extension UIView {
    func bringSelfToFront() {
        superview?.bringSubviewToFront(self)
    }
}
