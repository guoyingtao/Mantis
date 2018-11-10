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
    private var originalRatioH: Double
    
    init(type: RatioType, originalRatioH: Double) {
        self.type = type
        self.originalRatioH = originalRatioH
    }
    
    func present(by viewController: UIViewController, in sourceView: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let fixedRatios = FixedRatioManager(originalRatioH: self.originalRatioH)
        if Config.shared.hasCustomRatios() {
            fixedRatios.appendToTail(items: Config.shared.customRatios)
        }
        
        fixedRatios.sort(isByHorizontal: (type == .horizontal))
        
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
            // https://stackoverflow.com/a/27823616/288724
            actionSheet.popoverPresentationController?.permittedArrowDirections = .any
            actionSheet.popoverPresentationController?.sourceView = sourceView
            actionSheet.popoverPresentationController?.sourceRect = sourceView.bounds
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(cancelAction)
        
        viewController.present(actionSheet, animated: true)
    }
}
