//
//  RotationDialViewModelProtocol.swift
//  Mantis
//
//  Created by yingtguo on 1/18/23.
//

import Foundation

protocol RotationControlViewModelProtocol {
    var rotationAngle: Angle { get set }
    var didSetRotationAngle: (Angle) -> Void { get set }
}

protocol RotationDialViewModelProtocol: RotationControlViewModelProtocol {
    var touchPoint: CGPoint? { get set }
    func setup(with midPoint: CGPoint)
}
