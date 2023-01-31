//
//  CropAuxiliaryIndicatorViewProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import UIKit

enum GridLineNumberType {
    case none
    case crop
    case rotate
    
    func getHelpLineNumber() -> Int {
        switch self {
        case .none:
            return 0
        case .crop:
            return 2
        case .rotate:
            return 8
        }
    }
}

protocol CropAuxiliaryIndicatorViewProtocol: UIView {
    var gridLineNumberType: GridLineNumberType { get set }
    var gridHidden: Bool { get set }
    
    func setGrid(hidden: Bool, animated: Bool)
    func hideGrid()
    func handleCornerHandleTouched(with tappedEdge: CropViewOverlayEdge)
    func handleEdgeUntouched()
}
