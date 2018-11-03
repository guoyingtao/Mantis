//
//  RatioPresenter.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class RatioPresenter {
    var didGetRatio: ((Double)->Void) = { _ in }
    var type: RatioType = .vertical
    var originalRatio: Double
    
    init(type: RatioType, originalRatio: Double) {
        self.type = type
        self.originalRatio = originalRatio
    }
    
    func present(in viewController: UIViewController) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for ratio in FixedRatiosType.allCases {
            let title = ratio.getText(by: type)
            
            let action = UIAlertAction(title: title, style: .default) {[weak self] _ in
                guard let self = self else { return }
                let ratioValue = (ratio == .original) ? self.originalRatio : ratio.getRatio(by: self.type)
                self.didGetRatio(ratioValue)
            }
            actionSheet.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(cancelAction)
        
        viewController.present(actionSheet, animated: true)
    }
}
