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
    
    func findSubview<T: UIView>(withAccessibilityIdentifier accessibilityIdentifier: String) -> T? {
        if self.accessibilityIdentifier == accessibilityIdentifier {
            return self as? T
        }
        
        for subview in self.subviews {
            if let matchingSubview = subview.findSubview(withAccessibilityIdentifier: accessibilityIdentifier) as? T {
                return matchingSubview
            }
        }
        
        return nil
    }
}
