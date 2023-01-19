//
//  RotationDialViewModelProtocol.swift
//  Mantis
//
//  Created by yingtguo on 1/18/23.
//

import Foundation

protocol RotationDialViewModelProtocol {
    var didSetRotationAngle: (CGAngle) -> Void { get set }
    var touchPoint: CGPoint? { get set }
    func setup(with midPoint: CGPoint)
}
