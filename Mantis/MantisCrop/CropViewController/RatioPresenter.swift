//
//  RatioPresenter.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

enum RatioType {
    case horizontal
    case vertical
}

class RatioPresenter {
    var didGetRatio: ((Double)->Void) = { _ in }
    private var type: RatioType = .vertical
    private var originalRatio: Double
    
    init(type: RatioType, originalRatio: Double) {
        self.type = type
        self.originalRatio = originalRatio
    }
    
    func present(by viewController: UIViewController, in sourceView: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let fixedRatios = FixedRatioManager(originalRatio: self.originalRatio)
        if Config.shared.customRatios.count > 0 {
            fixedRatios.appendToTail(ratioItems: Config.shared.customRatios)
        }
        
        for ratio in fixedRatios.ratios {
            let title = (type == .horizontal) ? ratio.nameH : ratio.nameV
            
            let action = UIAlertAction(title: title, style: .default) {[weak self] _ in
                guard let self = self else { return }
                let ratioValue = (self.type == .horizontal) ? ratio.ratioH : ratio.ratioV
                self.didGetRatio(ratioValue)
            }
            actionSheet.addAction(action)
        }
        
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            actionSheet.popoverPresentationController?.permittedArrowDirections = .any
            actionSheet.popoverPresentationController?.sourceView = sourceView
//            actionSheet.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(cancelAction)
        
        viewController.present(actionSheet, animated: true)
    }
}
