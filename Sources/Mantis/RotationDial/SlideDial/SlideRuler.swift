//
//  SlideRuler.swift
//  Inchworm
//
//  Created by Echo on 10/16/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import UIKit

private let scaleBarNumber = 41
private let majorScaleBarNumber = 5
private let scaleWidth: CGFloat = 1
private let pointerWidth: CGFloat = 1

protocol SlideRulerDelegate: AnyObject {
    func didGetOffsetRatio(from slideRuler: SlideRuler, offsetRatio: CGFloat)
    func didFinishScroll()
}

class SlideRuler: UIView {
    var forceAlignCenterFeedback = true
    let pointer = CALayer()
    let centralDot = CAShapeLayer()
    let scrollRulerView = UIScrollView()
    let dotWidth: CGFloat = 6
    var sliderOffsetRatio: CGFloat = 0.5
    var positionInfoHelper: SlideRulerPositionHelper = BilateralTypeSlideRulerPositionHelper()
    
    let scaleBarLayer: CAReplicatorLayer = {
        var layer = CAReplicatorLayer()
        layer.instanceCount = scaleBarNumber
        return layer
    }()
    
    let majorScaleBarLayer: CAReplicatorLayer = {
        var layer = CAReplicatorLayer()
        layer.instanceCount = majorScaleBarNumber
        return layer
    }()
    
    weak var delegate: SlideRulerDelegate?
    var isReset = false
    var offsetValue: CGFloat = 0
    
    override var bounds: CGRect {
        didSet {
            setUIFrames()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        positionInfoHelper = BilateralTypeSlideRulerPositionHelper()
        positionInfoHelper.slideRuler = self
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
        
    private func setupUI() {
        setupSlider()
        makeRuler()
        makeCentralDot()
        makePointer()
        
        setUIFrames()
    }
    
    @objc func setSliderDelegate() {
        scrollRulerView.delegate = self
    }
    
    func setUIFrames() {
        sliderOffsetRatio = positionInfoHelper.getInitialOffsetRatio()
        scrollRulerView.frame = bounds

        offsetValue = sliderOffsetRatio * scrollRulerView.frame.width
        scrollRulerView.delegate = nil
        scrollRulerView.contentSize = CGSize(width: frame.width * 2, height: frame.height)
        scrollRulerView.contentOffset = CGPoint(x: offsetValue, y: 0)
        
        perform(#selector(setSliderDelegate), with: nil, afterDelay: 0.1)

        pointer.frame = CGRect(x: (frame.width / 2 - pointerWidth / 2),
                               y: bounds.origin.y + frame.height * 0.4,
                               width: pointerWidth,
                               height: frame.height * 0.6)
        
        let centralDotOriginX = positionInfoHelper.getCentralDotOriginX()
        centralDot.frame = CGRect(x: centralDotOriginX, y: frame.height * 0.35, width: dotWidth, height: dotWidth)
        
        centralDot.path = UIBezierPath(ovalIn: centralDot.bounds).cgPath
        
        scaleBarLayer.frame = CGRect(x: frame.width / 2, y: 0.6 * frame.height, width: frame.width, height: 0.4 * frame.height)
        scaleBarLayer.instanceTransform = CATransform3DMakeTranslation((frame.width - scaleWidth) / CGFloat((scaleBarNumber - 1)), 0, 0)

        scaleBarLayer.sublayers?.forEach {
            $0.frame = CGRect(x: 0, y: 0, width: 1, height: scaleBarLayer.frame.height)
        }
        
        majorScaleBarLayer.frame = scaleBarLayer.frame
        majorScaleBarLayer.instanceTransform = CATransform3DMakeTranslation((frame.width - scaleWidth) / CGFloat((majorScaleBarNumber - 1)), 0, 0)
        
        majorScaleBarLayer.sublayers?.forEach {
            $0.frame = CGRect(x: 0, y: 0, width: 1, height: majorScaleBarLayer.frame.height)
        }
    }
    
    private func setupSlider() {
        addSubview(scrollRulerView)
        
        scrollRulerView.showsHorizontalScrollIndicator = false
        scrollRulerView.showsVerticalScrollIndicator = false
        scrollRulerView.isUserInteractionEnabled = true
        scrollRulerView.delegate = self
    }
    
    private func makePointer() {
        pointer.backgroundColor = UIColor.white.cgColor
        layer.addSublayer(pointer)
    }
    
    private func makeCentralDot() {
        centralDot.fillColor = UIColor.white.cgColor
        scrollRulerView.layer.addSublayer(centralDot)
    }
    
    private func makeRuler() {
        scaleBarLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let scaleBar = makeBarScaleMark(byColor: UIColor.gray.cgColor)
        scaleBarLayer.addSublayer(scaleBar)
        
        scrollRulerView.layer.addSublayer(scaleBarLayer)
        
        majorScaleBarLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let majorScaleBar = makeBarScaleMark(byColor: UIColor.white.cgColor)
        majorScaleBarLayer.addSublayer(majorScaleBar)
        
        scrollRulerView.layer.addSublayer(majorScaleBarLayer)
    }
    
    private func makeBarScaleMark(byColor color: CGColor) -> CALayer {
        let bar = CALayer()
        bar.backgroundColor = color
        
        return bar
    }
    
    func reset() {
        let offset = CGPoint(x: offsetValue, y: 0)
        scrollRulerView.delegate = nil
        scrollRulerView.setContentOffset(offset, animated: false)
        scrollRulerView.delegate = self
        
        centralDot.isHidden = true
        let color = UIColor.gray.cgColor
        scaleBarLayer.sublayers?.forEach { $0.backgroundColor = color}
        majorScaleBarLayer.sublayers?.forEach { $0.backgroundColor = color}
    }
    
    func handleRemoveTempResetWith(progress: Float) {
        centralDot.fillColor = UIColor.white.cgColor
        
        scaleBarLayer.sublayers?.forEach { $0.backgroundColor = UIColor.gray.cgColor}
        majorScaleBarLayer.sublayers?.forEach { $0.backgroundColor = UIColor.white.cgColor}
        
        scrollRulerView.delegate = nil
        
        let offsetX = positionInfoHelper.getRulerOffsetX(with: CGFloat(progress))
        let offset = CGPoint(x: offsetX, y: 0)
        scrollRulerView.setContentOffset(offset, animated: false)
        scrollRulerView.delegate = self
        
        checkCentralDotHiddenStatus()
    }
    
    func checkCentralDotHiddenStatus() {
        centralDot.isHidden = (scrollRulerView.contentOffset.x == frame.width / 2)
    }
    
    func getTouchTarget() -> UIView {
        return scrollRulerView
    }
    
    func setOffset(offsetRatio: CGFloat) {
        positionInfoHelper.setOffset(offsetRatio: offsetRatio)
    }
}

extension SlideRuler: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        checkCentralDotHiddenStatus()
        delegate?.didFinishScroll()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        centralDot.isHidden = false
        
        let speed = scrollView.panGestureRecognizer.velocity(in: scrollView.superview)
        
        let limit = frame.width / CGFloat((scaleBarNumber - 1) * 2)
        
        func checkIsCenterPosition() -> Bool {
            return positionInfoHelper.checkIsCenterPosition(with: limit)
        }        
        
        if checkIsCenterPosition() && abs(speed.x) < 10.0 {
            
            if !isReset {
                isReset = true
                
                if forceAlignCenterFeedback {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
                
                func forceAlignCenter() {
                    let offset = CGPoint(x: positionInfoHelper.getForceAlignCenterX(), y: 0)
                    scrollView.setContentOffset(offset, animated: false)
                    delegate?.didGetOffsetRatio(from: self, offsetRatio: 0)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    forceAlignCenter()
                }
                
                forceAlignCenter()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
                    usleep(1000000)
                }
            }
        } else {
            isReset = false
        }
        
        let offsetRatio = positionInfoHelper.getOffsetRatio()
        delegate?.didGetOffsetRatio(from: self, offsetRatio: offsetRatio)
        
        positionInfoHelper.handleOffsetRatioWhenScrolling(scrollView)
    }
}
