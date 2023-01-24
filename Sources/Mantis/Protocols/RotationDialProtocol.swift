//
//  RotationDialProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import UIKit

protocol RotationDialProtocol: UIView {
    var pointerHeight: CGFloat { get set }
    var spanBetweenDialPlateAndPointer: CGFloat { get set }
    var pointerWidth: CGFloat { get set }
    var didRotate: (_ angle: CGAngle) -> Void { get set }
    var didFinishedRotate: () -> Void { get set }
    
    func setup(with frame: CGRect)
    @discardableResult func rotateDialPlate(by angle: CGAngle) -> Bool
    func rotateDialPlate(to angle: CGAngle, animated: Bool)
    func resetAngle(animated: Bool)
    func getRotationAngle() -> CGAngle
    func setRotationCenter(by point: CGPoint, of view: UIView)
    func reset()
}
