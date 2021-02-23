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
    private var ratios: [RatioItemType]
    private var fixRatiosShowType: FixRatiosShowType = .adaptive
    
    init(type: RatioType, originalRatioH: Double, ratios: [RatioItemType] = [], fixRatiosShowType: FixRatiosShowType = .adaptive) {
        self.type = type
        self.originalRatioH = originalRatioH
        self.ratios = ratios
        self.fixRatiosShowType = fixRatiosShowType
    }
    
    private func getItemTitle(by ratio: RatioItemType)-> String {
        switch fixRatiosShowType {
        case .adaptive:
            return (type == .horizontal) ? ratio.nameH : ratio.nameV
        case .horizontal:
            return ratio.nameH
        case .vetical:
            return ratio.nameV
        }
    }
    
    private func getItemValue(by ratio: RatioItemType)-> Double {
        switch fixRatiosShowType {
        case .adaptive:
            return (type == .horizontal) ? ratio.ratioH : ratio.ratioV
        case .horizontal:
            return ratio.ratioH
        case .vetical:
            return ratio.ratioV
        }
    }
    
    func present(by viewController: UIViewController, in sourceView: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for ratio in ratios {
            let title = getItemTitle(by: ratio)
            
            let action = UIAlertAction(title: title, style: .default) {[weak self] _ in
                guard let self = self else { return }
                let ratioValue = self.getItemValue(by: ratio)
                self.didGetRatio(ratioValue)
            }
            actionSheet.addAction(action)
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            // https://stackoverflow.com/a/27823616/288724
            actionSheet.popoverPresentationController?.permittedArrowDirections = .any
            actionSheet.popoverPresentationController?.sourceView = sourceView
            actionSheet.popoverPresentationController?.sourceRect = sourceView.bounds
        }
        
        let cancelText = LocalizedHelper.getString("Cancel")
        let cancelAction = UIAlertAction(title: cancelText, style: .cancel)
        actionSheet.addAction(cancelAction)
        
        viewController.present(actionSheet, animated: true)
    }
}
