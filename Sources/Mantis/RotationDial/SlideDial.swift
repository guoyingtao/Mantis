//
//  SlideDial.swift
//  Mantis
//
//  Created by Yingtao Guo on 6/16/23.
//

import UIKit

private let slideRulerSpan: CGFloat = 50
private let indicatorSize = CGSize(width: 40, height: 40)

final class SlideDial: UIView, RotationControlViewProtocol {
    var isAttachedToCropView = true
    
    var didUpdateRotationValue: (Angle) -> Void = { _ in }
    
    var didFinishRotation: () -> Void = {}
    
    var indicator: UILabel!
    
    var slideRuler: SlideRuler!
            
    @discardableResult func updateRotationValue(by angle: Angle) -> Bool {
        indicator.text = "\(Int(round(angle.degrees)))"
        return true
    }
    
    func reset() {
        if let slideRuler = slideRuler {
            slideRuler.reset()
        }
    }
    
    func getTouchTarget() -> UIView {
        slideRuler.getTouchTarget()
    }
            
    func setupUI(withAllowableFrame allowableFrame: CGRect) {
        frame = allowableFrame
        createIndicator()
        createSlideRuler()
    }
    
    func createIndicator() {
        let indicatorFrame = CGRect(origin: CGPoint(x: (frame.width - indicatorSize.width) / 2, y: 0), size: indicatorSize)
        
        if let indicator = indicator {
            indicator.frame = indicatorFrame
        } else {
            indicator = UILabel(frame: indicatorFrame)
            indicator.textColor = .white
            indicator.textAlignment = .center
            addSubview(indicator)
        }
    }
    
    func createSlideRuler() {
        let sliderFrame = CGRect(x: 0,
                                 y: frame.height - slideRulerSpan,
                                 width: frame.width,
                                 height: slideRulerSpan)
        
        if let slideRuler = slideRuler {
            slideRuler.frame = sliderFrame
        } else {
            slideRuler = SlideRuler(frame: sliderFrame)
            slideRuler.delegate = self
            slideRuler.forceAlignCenterFeedback = true
            addSubview(slideRuler)
        }        
    }
}

extension SlideDial: SlideRulerDelegate {
    func didFinishScroll() {
        didFinishRotation()
    }
    
    func didGetOffsetRatio(from slideRuler: SlideRuler, offsetRatio: CGFloat) {
        let angle = Angle(degrees: 40 * offsetRatio)
        updateRotationValue(by: angle)
        didUpdateRotationValue(angle)
    }
}
