//
//  SlideRuler.swift
//  Inchworm
//
//  Created by Echo on 10/16/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import UIKit

private let scaleWidth: CGFloat = 2
private let pointerWidth: CGFloat = 2

protocol SlideRulerDelegate: AnyObject {
    func didGetOffsetRatio(from slideRuler: SlideRuler, offsetRatio: CGFloat)
    func didFinishScroll()
}

final class SlideRuler: UIView {
    var forceAlignCenterFeedback = true
    let pointer = CALayer()
    let centralDot = CAShapeLayer()
    let scrollRulerView = UIScrollView()
    let dotWidth: CGFloat = 6
    var sliderOffsetRatio: CGFloat = 0.5
    var positionInfoHelper: SlideRulerPositionHelper = BilateralTypeSlideRulerPositionHelper()
        
    let scaleBarLayer = CALayer()
    let majorScaleBarLayer = CALayer()
    private var scaleBars: [CALayer] = []
    private var majorScaleBars: [CALayer] = []
    
    weak var delegate: SlideRulerDelegate?
    var isReset = false
    var offsetValue: CGFloat = 0
    
    private var lastTickIndex: Int?
    
    override var bounds: CGRect {
        didSet {
            setUIFrames()
        }
    }
    
    let config: SlideDialConfig!
    let scaleColor: CGColor!
    let majorScaleColor: CGColor!
    
    init(frame: CGRect, config: SlideDialConfig) {
        self.config = config
        scaleColor = config.scaleColor.cgColor
        majorScaleColor = config.majorScaleColor.cgColor

        super.init(frame: frame)
        
        positionInfoHelper = BilateralTypeSlideRulerPositionHelper()
        positionInfoHelper.slideRuler = self
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *),
           traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            pointer.backgroundColor = config.pointerColor.cgColor
            centralDot.fillColor = config.centralDotColor.cgColor
            let newScaleColor = config.scaleColor.cgColor
            let newMajorScaleColor = config.majorScaleColor.cgColor
            scaleBars.forEach { $0.backgroundColor = newScaleColor }
            majorScaleBars.forEach { $0.backgroundColor = newMajorScaleColor }
        }
    }
        
    func setupUI() {
        setupSlider()
        makeRuler()
        makeCentralDot()
        makePointer()
        
        setUIFrames()
        updateLastTickIndex()
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
        updateLastTickIndex()

        pointer.frame = CGRect(x: (frame.width / 2 - pointerWidth / 2),
                               y: bounds.origin.y + frame.height * 0.25,
                               width: pointerWidth,
                               height: frame.height * 0.75)
        
        let centralDotCenterX = positionInfoHelper.getCentralDotCenterX()
        centralDot.bounds = CGRect(x: 0, y: 0, width: dotWidth, height: dotWidth)
        centralDot.position = CGPoint(x: centralDotCenterX, y: frame.height * 0.38 + dotWidth / 2)
        centralDot.path = UIBezierPath(ovalIn: centralDot.bounds).cgPath
        
        scaleBarLayer.frame = CGRect(x: frame.width / 2, y: 0.65 * frame.height, width: frame.width, height: 0.35 * frame.height)
        let scaleSpacing = config.scaleBarNumber > 1
            ? frame.width / CGFloat(config.scaleBarNumber - 1)
            : 0
        for (index, bar) in scaleBars.enumerated() {
            let xPosition = CGFloat(index) * scaleSpacing
            bar.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            bar.bounds = CGRect(x: 0, y: 0, width: scaleWidth, height: scaleBarLayer.frame.height)
            bar.position = CGPoint(x: xPosition, y: scaleBarLayer.frame.height)
        }
        
        majorScaleBarLayer.frame = scaleBarLayer.frame
        let majorSpacing = config.majorScaleBarNumber > 1
            ? frame.width / CGFloat(config.majorScaleBarNumber - 1)
            : 0
        for (index, bar) in majorScaleBars.enumerated() {
            let xPosition = CGFloat(index) * majorSpacing
            bar.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            bar.bounds = CGRect(x: 0, y: 0, width: scaleWidth, height: majorScaleBarLayer.frame.height)
            bar.position = CGPoint(x: xPosition, y: majorScaleBarLayer.frame.height)
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
        pointer.backgroundColor = config.pointerColor.cgColor
        layer.addSublayer(pointer)
    }
    
    private func makeCentralDot() {
        centralDot.fillColor = config.centralDotColor.cgColor
        scrollRulerView.layer.addSublayer(centralDot)
    }
    
    private func makeRuler() {
        scaleBars.forEach { $0.removeFromSuperlayer() }
        scaleBars.removeAll()
        
        for _ in 0..<config.scaleBarNumber {
            let scaleBar = makeBarScaleMark(byColor: scaleColor)
            scaleBars.append(scaleBar)
            scaleBarLayer.addSublayer(scaleBar)
        }
        
        if scaleBarLayer.superlayer == nil {
            scrollRulerView.layer.addSublayer(scaleBarLayer)
        }
        
        majorScaleBars.forEach { $0.removeFromSuperlayer() }
        majorScaleBars.removeAll()

        for _ in 0..<config.majorScaleBarNumber {
            let majorScaleBar = makeBarScaleMark(byColor: majorScaleColor)
            majorScaleBars.append(majorScaleBar)
            majorScaleBarLayer.addSublayer(majorScaleBar)
        }
        
        if majorScaleBarLayer.superlayer == nil {
            scrollRulerView.layer.addSublayer(majorScaleBarLayer)
        }
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
        updateLastTickIndex()
        
        centralDot.isHidden = true
        scaleBars.forEach { $0.backgroundColor = scaleColor }
        majorScaleBars.forEach { $0.backgroundColor = majorScaleColor }
    }
        
    func checkCentralDotHiddenStatus() {
        let tolerance = frame.width / CGFloat((config.scaleBarNumber - 1) * 2)
        let isAtCenter = abs(scrollRulerView.contentOffset.x - frame.width / 2) < tolerance
        centralDot.isHidden = isAtCenter
    }
    
    func getTouchTarget() -> UIView {
        return scrollRulerView
    }
    
    func setOffsetRatio(_ offsetRatio: CGFloat) {
        scrollRulerView.delegate = nil
        positionInfoHelper.setOffset(offsetRatio: offsetRatio)
        scrollRulerView.delegate = self
        updateLastTickIndex()
    }

    private func updateLastTickIndex() {
        lastTickIndex = currentTickIndex()
    }

    private func currentTickIndex() -> Int? {
        guard !scaleBars.isEmpty else {
            return nil
        }

        let spacing = getTickSpacing()
        guard spacing > 0 else {
            return nil
        }

        let rawIndex = scrollRulerView.contentOffset.x / spacing
        let index = Int(rawIndex.rounded())
        return min(max(index, 0), scaleBars.count - 1)
    }

    private func getTickSpacing() -> CGFloat {
        guard config.scaleBarNumber > 1 else {
            return 0
        }

        return frame.width / CGFloat(config.scaleBarNumber - 1)
    }

    private func getMajorTickStep() -> Int? {
        guard config.scaleBarNumber > 1, config.majorScaleBarNumber > 1 else {
            return nil
        }

        let step = (config.scaleBarNumber - 1) / (config.majorScaleBarNumber - 1)
        return step > 0 ? step : nil
    }

    private func animateTick(at index: Int) {
        guard index >= 0, index < scaleBars.count else {
            return
        }

        let bar = scaleBars[index]
        let barHeight = scaleBarLayer.frame.height
        let expandedHeight = pointer.frame.height

        let heightAnimation = CAKeyframeAnimation(keyPath: "bounds.size.height")
        heightAnimation.values = [barHeight, expandedHeight, barHeight]
        heightAnimation.keyTimes = [0, 0.35, 1]
        heightAnimation.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeIn)
        ]
        heightAnimation.duration = 0.18
        heightAnimation.isRemovedOnCompletion = true

        bar.add(heightAnimation, forKey: "tickBounce")
    }

    private func animateMajorTick(at index: Int) {
        guard index >= 0, index < majorScaleBars.count else {
            return
        }

        let bar = majorScaleBars[index]
        let barHeight = majorScaleBarLayer.frame.height
        let expandedHeight = pointer.frame.height

        let heightAnimation = CAKeyframeAnimation(keyPath: "bounds.size.height")
        heightAnimation.values = [barHeight, expandedHeight, barHeight]
        heightAnimation.keyTimes = [0, 0.35, 1]
        heightAnimation.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeIn)
        ]
        heightAnimation.duration = 0.18
        heightAnimation.isRemovedOnCompletion = true

        bar.add(heightAnimation, forKey: "majorTickBounce")
    }

    private func handleTickAnimationIfNeeded() {
        guard scrollRulerView.isDragging || scrollRulerView.isDecelerating else {
            return
        }

        guard let currentIndex = currentTickIndex() else {
            return
        }

        guard let previousIndex = lastTickIndex else {
            lastTickIndex = currentIndex
            return
        }

        guard currentIndex != previousIndex else {
            return
        }

        animateTick(at: previousIndex)
        if let step = getMajorTickStep(), previousIndex % step == 0 {
            let majorIndex = previousIndex / step
            animateMajorTick(at: majorIndex)
        }
        lastTickIndex = currentIndex
    }
}

extension SlideRuler: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        checkCentralDotHiddenStatus()
        delegate?.didFinishScroll()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.didFinishScroll()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        checkCentralDotHiddenStatus()
        handleTickAnimationIfNeeded()
        
        let speed = scrollView.panGestureRecognizer.velocity(in: scrollView.superview)
        
        let limit = frame.width / CGFloat((config.scaleBarNumber - 1) * 2)
        
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
