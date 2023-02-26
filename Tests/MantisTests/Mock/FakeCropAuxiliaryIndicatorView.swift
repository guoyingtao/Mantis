//
//  FakeCropAuxiliaryIndicatorView.swift
//  Mantis
//
//  Created by Yingtao Guo on 2/3/23.
//

import UIKit
@testable import Mantis

class FakeCropAuxiliaryIndicatorView: UIView, CropAuxiliaryIndicatorViewProtocol {
    var gridLineNumberType: GridLineNumberType = .none
    
    var gridHidden = false
    
    func setGrid(hidden: Bool, animated: Bool) {
        
    }
    
    func hideGrid() {
        
    }
    
    func handleIndicatorHandleTouched(with tappedEdge: CropViewAuxiliaryIndicatorHandleType) {
        
    }
    
    func handleEdgeUntouched() {
        
    }
}
