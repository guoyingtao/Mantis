//
//  RotationDial+Touches.swift
//  PufferExample
//
//  Created by Echo on 5/23/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import UIKit

extension RotationDial {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let newPoint = convert(point, to: self)
        if bounds.contains(newPoint) {
            return self
        }
        
        return nil
    }
    
    private func handle(_ touches: Set<UITouch>) {
        guard touches.count == 1,
            let touch = touches.first else {
                return
        }
        
        viewModel.touchPoint = touch.location(in: self)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        handle(touches)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        handle(touches)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        didFinishRotation()
        viewModel.touchPoint = nil
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        
        return true
    }
}
