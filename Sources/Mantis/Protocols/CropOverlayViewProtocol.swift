//
//  CropOverlayViewProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import UIKit

protocol CropOverlayViewProtocol: UIView {
    func setGrid(hidden: Bool, animated: Bool)
    func hideGrid()
    func handleEdgeTouched(with tappedEdge: CropViewOverlayEdge)
    func handleEdgeUntouched()
}
