//
//  RotationDial.swift
//
//  Created by Echo on 10/21/18.
//  Copyright © 2018 Echo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

@IBDesignable
final class RotationDial: UIView {
    var isAttachedToCropView = true
    
    var pointerHeight: CGFloat = 8
    var spanBetweenDialPlateAndPointer: CGFloat = 6
    var pointerWidth: CGFloat = 8 * sqrt(2)
    
    var didUpdateRotationValue: (_ angle: Angle) -> Void = { _ in }
    var didFinishRotation: () -> Void = { }
    
    var viewModel: RotationDialViewModelProtocol
    
    private var config: RotationDialConfig
    
    private let angleLimit = Angle(degrees: Constants.rotationDegreeLimit)
    private let showRadiansLimit: CGFloat = 40 * .pi / 180
    private var dialPlate: RotationDialPlate?
    private var dialPlateHolder: UIView?
    private var pointer: CAShapeLayer = CAShapeLayer()
    
    init(frame: CGRect,
         config: RotationDialConfig,
         viewModel: RotationDialViewModelProtocol,
         dialPlate: RotationDialPlate) {
        self.config = config
        self.viewModel = viewModel
        self.dialPlate = dialPlate
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func accessibilityIncrement() {
        adjustRotationAngleForAccessibility(byDegrees: 1)
    }
    
    override func accessibilityDecrement() {
        adjustRotationAngleForAccessibility(byDegrees: -1)
    }
    
    /// Turns the dial plate by `delta` degrees within `angleLimit`, reports the
    /// new angle and calls `didFinishRotation()`, as lifting a finger does.
    /// It sets the plate directly: the touch path's stepping refuses a step
    /// that would cross the limit without reporting it.
    private func adjustRotationAngleForAccessibility(byDegrees delta: CGFloat) {
        let limit = angleLimit.degrees
        let currentDegrees = getRotationAngle().degrees
        let degrees = min(max(currentDegrees + delta, -limit), limit)
        // Already at the limit. The plate angle is read back with atan2f, so
        // allow for single-precision error.
        guard abs(degrees - currentDegrees) > 1e-3 else {
            return
        }
        
        let angle = Angle(degrees: degrees)
        rotateDialPlate(to: angle)
        setAccessibilityValue()
        didUpdateRotationValue(angle)
        didFinishRotation()
    }
}

// MARK: - private functions
extension RotationDial {
    private func setupUI() {
        clipsToBounds = true
        backgroundColor = config.backgroundColor
        setAccessibilities()
        
        dialPlateHolder?.removeFromSuperview()
        dialPlateHolder = getDialPlateHolder(by: config.orientation)
        addSubview(dialPlateHolder!)
        setupDialPlate(in: dialPlateHolder!)
        setupPointer(in: dialPlateHolder!)
        setDialPlateHolder(by: config.orientation)
    }
    
    private func setupViewModel() {
        viewModel.didSetRotationAngle = { [weak self] angle in
            self?.handleRotation(by: angle)
        }
        viewModel.setup(with: getRotationCenter())
    }
    
    private func handleRotation(by angle: Angle) {
        guard angle <= angleLimit else {
            return
        }

        if updateRotation(bySteppingAngle: angle) {
            let newAngle = getRotationAngle()
            didUpdateRotationValue(newAngle)
        }
    }
    
    private func getDialPlateHolder(by orientation: RotationDialConfig.Orientation) -> UIView {
        let view = UIView(frame: bounds)
        
        switch orientation {
        case .normal, .upsideDown:
            ()
        case .left, .right:
            view.frame.size = CGSize(width: view.bounds.height, height: view.bounds.width)
        }
        
        return view
    }
    
    private func setDialPlateHolder(by orientation: RotationDialConfig.Orientation) {
        switch orientation {
        case .normal:
            ()
        case .left:
            dialPlateHolder?.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            dialPlateHolder?.frame.origin = CGPoint(x: 0, y: 0)
        case .right:
            dialPlateHolder?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            dialPlateHolder?.frame.origin = CGPoint(x: 0, y: 0)
        case .upsideDown:
            dialPlateHolder?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            dialPlateHolder?.frame.origin = CGPoint(x: 0, y: 0)
        }
    }
    
    private func setupDialPlate(in container: UIView) {
        let margin = CGFloat(config.margin)
        var dialPlateShowHeight = container.frame.height - margin - pointerHeight - spanBetweenDialPlateAndPointer
        var radius = dialPlateShowHeight / (1 - cos(showRadiansLimit))
        
        if radius * 2 * sin(showRadiansLimit) > container.frame.width {
            radius = (container.frame.width / 2) / sin(showRadiansLimit)
            dialPlateShowHeight = radius - radius * cos(showRadiansLimit)
        }
        
        let dialPlateLength = 2 * radius
        let dialPlateFrame = CGRect(x: (container.frame.width - dialPlateLength) / 2,
                                    y: margin - (dialPlateLength - dialPlateShowHeight),
                                    width: dialPlateLength,
                                    height: dialPlateLength)
        
        dialPlate?.removeFromSuperview()
        dialPlate?.setup(with: dialPlateFrame)
        container.addSubview(dialPlate!)
    }
    
    private func setupPointer(in container: UIView) {
        guard let dialPlate = dialPlate else { return }
        
        let path = CGMutablePath()
        let pointerEdgeLength: CGFloat = pointerWidth
        
        let pointTop = CGPoint(x: container.bounds.width/2, y: dialPlate.frame.maxY + spanBetweenDialPlateAndPointer)
        let pointLeft = CGPoint(x: container.bounds.width/2 - pointerEdgeLength / 2, y: pointTop.y + pointerHeight)
        let pointRight = CGPoint(x: container.bounds.width/2 + pointerEdgeLength / 2, y: pointLeft.y)
        
        path.move(to: pointTop)
        path.addLine(to: pointLeft)
        path.addLine(to: pointRight)
        path.addLine(to: pointTop)
        pointer.fillColor = config.indicatorColor.cgColor
        pointer.path = path
        container.layer.addSublayer(pointer)
    }
    
    private func getRotationCenter() -> CGPoint {
        guard let dialPlate = dialPlate else { return .zero }
        
        if case .custom(let center) = config.rotationCenterType {
            return center
        } else {
            let point = CGPoint(x: dialPlate.bounds.midX, y: dialPlate.bounds.midY)
            return dialPlate.convert(point, to: self)
        }
    }
}

extension RotationDial: RotationDialProtocol {
    func setupUI(withAllowableFrame allowableFrame: CGRect) {
        self.frame = allowableFrame        
        setupUI()
        setupViewModel()
    }
    
    private func updateRotation(bySteppingAngle steppingAngle: Angle) -> Bool {
        guard let dialPlate = dialPlate else { return false }
        
        let radians = steppingAngle.radians
        
        guard radians != 0 else { return false }
        
        if (getRotationAngle() * steppingAngle).radians >= 0 && abs(getRotationAngle().radians + radians) > angleLimit.radians {
            
            if radians > 0 {
                rotateDialPlate(to: angleLimit)
            } else {
                rotateDialPlate(to: -angleLimit)
            }
            
            return false
        }

        dialPlate.transform = dialPlate.transform.rotated(by: radians)
        setAccessibilityValue()
        
        return true
    }
    
    @discardableResult
    func updateRotationValue(by angle: Angle) -> Bool {
        if abs(angle.degrees) > angleLimit.degrees {
            return false
        }

        rotateDialPlate(to: angle)
        setAccessibilityValue()
        
        return true
    }
    
    func rotateDialPlate(to angle: Angle, animated: Bool = false) {
        guard abs(angle.radians) <= angleLimit.radians else {
            return
        }
        
        if animated {
            UIView.animate(withDuration: 0.5) {
                rotate()
            }
        } else {
            rotate()
        }
        
        func rotate() {
            dialPlate?.transform = CGAffineTransform(rotationAngle: angle.radians)
        }
    }
    
    func getRotationAngle() -> Angle {
        guard let dialPlate = dialPlate else { return Angle(degrees: 0) }        
        return dialPlate.getRotationAngle()
    }
    
    func setRotationCenter(by point: CGPoint, of view: UIView) {
        let newPoint = view.convert(point, to: self)
        config.rotationCenterType = .custom(center: newPoint)
    }
    
    func reset() {
        transform = .identity
        dialPlate?.reset()
        config.rotationCenterType = .useDefault
    }
    
    func getLengthRatio() -> CGFloat {
        config.lengthRatio
    }
    
    func getTotalRotationValue() -> CGFloat {
        getRotationAngle().degrees
    }
}
