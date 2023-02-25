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
    var didRotate: (_ angle: Angle) -> Void { get set }
    var didFinishedRotate: () -> Void { get set }
    
    func setup(with frame: CGRect)
    @discardableResult func rotateDialPlate(by angle: Angle) -> Bool
    func rotateDialPlate(to angle: Angle, animated: Bool)
    func resetAngle(animated: Bool)
    func getRotationAngle() -> Angle
    func setRotationCenter(by point: CGPoint, of view: UIView)
    func reset()
}
