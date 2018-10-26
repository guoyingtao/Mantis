//
//  CropView.swift
//  Mantis
//
//  Created by Echo on 10/20/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

enum CropViewOverlayEdge {
    case none
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
}

protocol CropViewDelegate {
    func cropViewDidBecomeResettable(_ cropView: CropView)
    func cropViewDidBecomeNonResettable(_ cropView: CropView)
}

typealias UpdateCropBoxFrameInfo = (aspectHorizontal: Bool, aspectVertical: Bool, clampMinFromTop: Bool, clampMinFromLeft: Bool)

class CropView: UIView {
    let cropViewMinimumBoxSize: CGFloat = 42
    var minimumAspectRatio: CGFloat = 0
    let angleDashboardHeight: CGFloat = 50
    
    fileprivate var viewStatus: CropViewStatus = .initial {
        didSet {
            render(by: viewStatus)
        }
    }
    
    fileprivate var imageStatus = ImageStatus()
    
    fileprivate var panOriginPoint = CGPoint.zero
    
    fileprivate var contentBounds: CGRect {
        var contentRect = CGRect.zero
        contentRect.origin.x = cropViewPadding
        contentRect.origin.y = cropViewPadding
        contentRect.size.width = bounds.width - 2 * cropViewPadding
        contentRect.size.height = bounds.height - 2 * cropViewPadding - angleDashboardHeight
    
        return contentRect
    }
    
    fileprivate var cropBoxFrame = CGRect.zero {
        didSet {
            if oldValue.equalTo(cropBoxFrame) { return }

            gridOverlayView.frame = cropBoxFrame
            dimmingView.adaptMaskTo(match: cropBoxFrame)
            visualEffectView.adaptMaskTo(match: cropBoxFrame)
        }
    }
    
    var delegate: CropViewDelegate?
    
    fileprivate var cropOrignFrame = CGRect.zero
    fileprivate var tappedEdge = CropViewOverlayEdge.none
    
    fileprivate var cropViewPadding:CGFloat = 14.0
    fileprivate var maximumZoomScale:CGFloat = 15.0
    fileprivate var minimumZoomScale:CGFloat = 1.0
    
    fileprivate var aspectRatio = CGSize(width: 16.0, height: 9.0)
    fileprivate var aspectRatioLockEnabled = false
    
    private lazy var initialCropBoxRect: CGRect = {
        guard let image = image else { return .zero }
        guard image.size.width > 0 && image.size.height > 0 else { return .zero }
        
        let outsideRect = contentBounds
        let insideRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        return GeometryHelper.getIncribeRect(fromOutsideRect: outsideRect, andInsideRect: insideRect)
    } ()
    
    fileprivate var image: UIImage!
    fileprivate var imageView: UIImageView!
    fileprivate var imageViewContainer: UIView!
    fileprivate var dimmingView: CropDimmingView!
    fileprivate var visualEffectView: CropVisualEffectView!
    fileprivate var angleDashboard: AngleDashboard!
    fileprivate var scrollView: CropScrollView!
    fileprivate var gridOverlayView: CropOverlayView!
    fileprivate var gridPanGestureRecognizer: UIPanGestureRecognizer!
    
    init(image: UIImage, imageStatus status: ImageStatus = ImageStatus()) {
        super.init(frame: CGRect.zero)
        self.image = image
        self.imageStatus = status
        initialSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func render(by viewStatus: CropViewStatus) {
        switch viewStatus {
        case .initial:
            setupUI()
        case .touchImage:
            showDimmingBackground()
            print("touch image")
        case .touchCropboxHandle:
            print("touch cropbox")
        case .touchRotationBoard:
            print("touch rotation")
        case .betweenOperation:
            showVisualEffectBackground()
            print("between Operation")
        }
    }
    
    private func setupUI() {
        setupScrollView()
        
        imageView = createImageView(image: image)
        imageViewContainer = UIView()
        imageViewContainer.addSubview(imageView)
        scrollView.addSubview(imageViewContainer)
        
        setupTranslucencyView()
        setupOverlayView()
        setGridOverlayView()
    }
    
    private func setupGestures() {
        // The pan controller to recognize gestures meant to resize the grid view
        gridPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(gridPanGestureRecognized))
        gridPanGestureRecognizer.delegate = self
        scrollView.panGestureRecognizer.require(toFail: gridPanGestureRecognizer)
        addGestureRecognizer(gridPanGestureRecognizer)
    }
    
    private func initialSetup() {
        viewStatus = .initial
        setupGestures()
    }
    
    func adaptForCropBox() {
        cropBoxFrame = initialCropBoxRect
        cropOrignFrame = cropBoxFrame
        
        scrollView.frame = initialCropBoxRect
        scrollView.contentSize = initialCropBoxRect.size
        scrollView.backgroundColor = .blue
        
        imageViewContainer.frame = scrollView.bounds
        imageView.frame = initialCropBoxRect
        imageView.center = CGPoint(x: imageViewContainer.bounds.width/2, y: imageViewContainer.bounds.height/2)
        setupAngleDashboard()
        
        // To do
        if aspectRatioLockEnabled {
            var cropBoxFrame = self.cropBoxFrame
            let scale = aspectRatio.width / aspectRatio.height
            let newWidth = cropBoxFrame.height / scale
            cropBoxFrame.origin.x += (cropBoxFrame.size.width - newWidth) / 2
            cropBoxFrame.size.width = newWidth
            self.cropBoxFrame = cropBoxFrame
            
            moveCroppedContentToCenter(animated: true)
        }
    }
    
    private func setupScrollView() {
        scrollView = CropScrollView(frame: bounds)
        scrollView.touchesBegan = { [weak self] in
            self?.viewStatus = .touchImage
        }
        
        scrollView.touchesEnded = { [weak self] in
            self?.viewStatus = .betweenOperation
        }

        scrollView.touchesCancelled = { [weak self] in
            self?.viewStatus = .betweenOperation
        }
        
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = maximumZoomScale
        scrollView.zoomScale = scrollView.minimumZoomScale
        scrollView.clipsToBounds = false
        scrollView.delegate = self
        
        addSubview(scrollView)
    }
    
    private func createImageView(image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.layer.minificationFilter = .trilinear
        imageView.accessibilityIgnoresInvertColors = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    private func setupOverlayView() {
        dimmingView = CropDimmingView()
        dimmingView.isUserInteractionEnabled = false
        dimmingView.alpha = 0
        addSubview(dimmingView)
    }
    
    private func setupTranslucencyView() {
        visualEffectView = CropVisualEffectView()
        visualEffectView.isUserInteractionEnabled = false
        addSubview(visualEffectView)
    }
    
    private func setGridOverlayView() {
        gridOverlayView = CropOverlayView()
        gridOverlayView.isUserInteractionEnabled = false
        gridOverlayView.gridHidden = true
        addSubview(gridOverlayView)
    }
    
    private func setupAngleDashboard() {
        if angleDashboard != nil {
            angleDashboard.removeFromSuperview()
        }
        
        let boardLength = min(bounds.width, bounds.height)
        let x:CGFloat = 0
        let y = gridOverlayView.frame.maxY
        angleDashboard = AngleDashboard(frame: CGRect(x: x, y: y, width: boardLength, height: angleDashboardHeight))
        addSubview(angleDashboard)
    }
    
    private func adaptAngleDashboardToCropBox() {
        angleDashboard.frame.origin.y = gridOverlayView.frame.maxY
    }
    
    fileprivate func updateCropBoxFrame(withGesturePoint point: CGPoint) {
        angleDashboard.isHidden = true

        let contentFrame = contentBounds
        
        var point = point
        point.x = max(contentFrame.origin.x - cropViewPadding, point.x)
        point.y = max(contentFrame.origin.y - cropViewPadding, point.y)
        
        //The delta between where we first tapped, and where our finger is now
        let xDelta = ceil(point.x - panOriginPoint.x)
        let yDelta = ceil(point.y - panOriginPoint.y)
        
        let newCropBoxFrame: CGRect
        if aspectRatioLockEnabled {
            var cropBoxLockedAspectFrameUpdater = CropBoxLockedAspectFrameUpdater(tappedEdge: tappedEdge, contentFrame: contentFrame, cropOriginFrame: cropOrignFrame, cropBoxFrame: cropBoxFrame)
            cropBoxLockedAspectFrameUpdater.updateCropBoxFrame(xDelta: xDelta, yDelta: yDelta)
            newCropBoxFrame = cropBoxLockedAspectFrameUpdater.cropBoxFrame
        } else {
            var cropBoxFreeAspectFrameUpdater = CropBoxFreeAspectFrameUpdater(tappedEdge: tappedEdge, contentFrame: contentFrame, cropOriginFrame: cropOrignFrame, cropBoxFrame: cropBoxFrame)
            cropBoxFreeAspectFrameUpdater.updateCropBoxFrame(xDelta: xDelta, yDelta: yDelta)
            newCropBoxFrame = cropBoxFreeAspectFrameUpdater.cropBoxFrame
        }
        
        guard newCropBoxFrame.width >= cropViewMinimumBoxSize && newCropBoxFrame.height >= cropViewMinimumBoxSize else {
            return
        }
        
        var imageRefFrame = CGRect(x: imageView.frame.origin.x - 1, y: imageView.frame.origin.y - 1, width: imageView.frame.width + 2, height: imageView.frame.height + 2 )
        imageRefFrame = imageView.convert(imageRefFrame, to: self)
        if imageRefFrame.contains(newCropBoxFrame) {
            cropBoxFrame = newCropBoxFrame
        }
    }
    
    fileprivate func isAngleDashboardTouched(forPoint point: CGPoint) -> Bool {
        return angleDashboard.frame.contains(point)
    }
    
    fileprivate func cropEdge(forPoint point: CGPoint) -> CropViewOverlayEdge {
        let touchUnit = CGFloat(64)
        let touchRect = cropBoxFrame.insetBy(dx: -touchUnit / 2, dy: -touchUnit / 2)
        let touchSize = CGSize(width: touchUnit, height: touchUnit)
        
        //Make sure the corners take priority
        let topLeftRect = CGRect(origin: touchRect.origin, size: touchSize)
        if topLeftRect.contains(point) { return .topLeft }
        
        let topRightRect = topLeftRect.offsetBy(dx: touchRect.width - touchUnit, dy: 0)
        if topRightRect.contains(point) { return .topRight }
        
        let bottomLeftRect = topLeftRect.offsetBy(dx: 0, dy: touchRect.height - touchUnit)
        if bottomLeftRect.contains(point) { return .bottomLeft }
        
        let bottomRightRect = bottomLeftRect.offsetBy(dx: touchRect.width - touchUnit, dy: 0)
        if bottomRightRect.contains(point) { return .bottomRight }
        
        //Check for edges
        let topRect = CGRect(origin: touchRect.origin, size: CGSize(width: touchRect.width, height: touchUnit))
        if topRect.contains(point) { return .top }
        
        let leftRect = CGRect(origin: touchRect.origin, size: CGSize(width: touchUnit, height: touchRect.height))
        if leftRect.contains(point) { return .left }
        
        let rightRect = CGRect(origin: CGPoint(x: touchRect.maxX - touchUnit, y: touchRect.origin.y), size: CGSize(width: touchUnit, height: touchRect.height))
        if rightRect.contains(point) { return .right }
        
        let bottomRect = CGRect(origin: CGPoint(x: touchRect.origin.x, y: touchRect.maxY - touchUnit), size: CGSize(width: touchRect.width, height: touchUnit))
        if bottomRect.contains(point) { return .bottom }
        
        return .none
    }
}

extension CropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageViewContainer
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        showDimmingBackground()
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        showDimmingBackground()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        showVisualEffectBackground()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        showVisualEffectBackground()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        showVisualEffectBackground()
    }
}

extension CropView {
    func showDimmingBackground() {
        UIView.animate(withDuration: 0.1) {
            self.dimmingView.alpha = 1
            self.visualEffectView.alpha = 0
        }
    }
    
    func showVisualEffectBackground() {
        UIView.animate(withDuration: 0.5) {
            self.dimmingView.alpha = 0
            self.visualEffectView.alpha = 1
        }
    }
}

extension CropView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        showDimmingBackground()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        showVisualEffectBackground()
    }
}

private var forCrop = true
private var currentPoint: CGPoint?
private var previousPoint: CGPoint?
private var rotationCal: RotationCalculator?
private var demoRotationCenterView: UIView?

extension CropView {
    
    func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        var newPoint = CGPoint(x: view.bounds.size.width * anchorPoint.x,
                               y: view.bounds.size.height * anchorPoint.y)
        
        
        var oldPoint = CGPoint(x: view.bounds.size.width * view.layer.anchorPoint.x,
                               y: view.bounds.size.height * view.layer.anchorPoint.y)
        
        newPoint = newPoint.applying(view.transform)
        oldPoint = oldPoint.applying(view.transform)
        
        var position = view.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.position = position
        view.layer.anchorPoint = anchorPoint
    }
    
    @objc func gridPanGestureRecognized(recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self)
        
        if recognizer.state == .began {
            if isAngleDashboardTouched(forPoint: point) {
                forCrop = false
                let rotationCenter = angleDashboard.convert(angleDashboard.getRotationCenter(), to: self)
                rotationCal = RotationCalculator(midPoint: rotationCenter)
                currentPoint = point
                previousPoint = point
                
                let rotationCenterOnImage = self.convert(rotationCenter, to: imageView)
                
                demoRotationCenterView?.removeFromSuperview()
                demoRotationCenterView = UIView(frame: CGRect(x: rotationCenterOnImage.x - 2, y: rotationCenterOnImage.y - 2, width: 4, height: 4))
                demoRotationCenterView?.backgroundColor = .red
//                imageView.addSubview(demoRotationCenterView!)
                
                // Do not use imageView frame because the frame will change after rotation!
                let anchorPoint = CGPoint(x: rotationCenterOnImage.x / imageView.bounds.width, y: rotationCenterOnImage.y / imageView.bounds.height)

                print("rotationCenterOnImage is \(rotationCenterOnImage)")
                setAnchorPoint(anchorPoint: anchorPoint, forView: imageView)
            } else {
                forCrop = true
                panOriginPoint = point
                cropOrignFrame = cropBoxFrame
                tappedEdge = cropEdge(forPoint: point)
                print("tappedEdge is \(tappedEdge)")
                showDimmingBackground()
            }
        }
        
        if recognizer.state == .ended {
            demoRotationCenterView?.removeFromSuperview()
            let anchorPoint = CGPoint(x: 0.5, y: 0.5)
            setAnchorPoint(anchorPoint: anchorPoint, forView: imageView)
            if forCrop {
                moveCroppedContentToCenter(animated: true)
            } else {
                currentPoint = nil
                previousPoint = nil
                rotationCal = nil
                
                let angle = angleDashboard.getRotationAngle()
                print("angle is \(angle)")
                print("image view scalex is \(imageView.transform.scaleX)")
                print("image view scaley is \(imageView.transform.scaleY)")
            }
            
            forCrop = true
            showVisualEffectBackground()
        }
        
        if recognizer.state == .changed {
            if forCrop {
                updateCropBoxFrame(withGesturePoint: point)
            } else {
                currentPoint = point
                if let rotation = rotationCal?.getRotation(byOldPoint: previousPoint!, andNewPoint: currentPoint!) {
                    if GeometryHelper.checkIf(outerView: imageView, coveredInnerView: gridOverlayView) {
                        angleDashboard.rotateDialPlate(by: rotation)
                        imageView.transform = imageView.transform.rotated(by: rotation)
                    } else {
                        print("un cover")
                        resetImageToCoverCropBox()
                    }
                } else {
                    resetImageToCoverCropBox()
                }
                
                previousPoint = currentPoint
            }
        }
    }
    
    private func resetImageToCoverCropBox() {
        
    }
}

extension CropView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == self.gridPanGestureRecognizer else { return true }
        
        let tapPoint = gestureRecognizer.location(in: self)
        
        let frame = gridOverlayView.frame
        let innerFrame = frame.insetBy(dx: 22, dy: 22)
        let outerFrame = frame.insetBy(dx: -22, dy: -22 - angleDashboardHeight)
        
        if (innerFrame.contains(tapPoint) || !outerFrame.contains(tapPoint)) {
            print("pan false")
            return false
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if gridPanGestureRecognizer.state == .changed {
            return false
        }
        
        return true
    }
}

extension CropView {
    func moveCroppedContentToCenter(animated: Bool = false) {
        
        var cropBoxFrame = self.cropBoxFrame
        let contentRect = contentBounds
        let scale = scrollView.zoomScale
        cropBoxFrame = GeometryHelper.getIncribeRect(fromOutsideRect: contentRect, andInsideRect: cropBoxFrame)
        
        var rect = convert(self.cropBoxFrame, to: scrollView)
        rect = CGRect(x: rect.minX/scale, y: rect.minY/scale, width: rect.width/scale, height: rect.height/scale)
        
        func translate() {
            scrollView.frame = cropBoxFrame
            scrollView.contentSize = cropBoxFrame.size
            scrollView.zoom(to: rect, animated: false)

            self.cropBoxFrame = cropBoxFrame
            adaptAngleDashboardToCropBox()
        }
        
        if animated == false {
            translate()
        } else {
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .beginFromCurrentState, animations: {translate()}, completion: { [weak self] _ in
                self?.angleDashboard.isHidden = false
            })
        }
    }
}

// public api
extension CropView {
    func crop() -> UIImage? {
        print("imageView bounds is \(imageView.bounds)")
        let cropRect = gridOverlayView.convert(gridOverlayView.bounds, to: imageView)
        print("cropRect is \(cropRect)")
        
        guard let cgImage = imageView.image?.cgImage else {
            return nil
        }
        
        let imageWidth = imageView.frame.width
        let scale = CGFloat(cgImage.width) / imageWidth
        
        let realCropRect = CGRect(x: cropRect.origin.x * scale, y: cropRect.origin.y * scale, width: cropRect.width * scale, height: cropRect.height * scale)
        print("realCropRect is \(realCropRect)")
        
        let croppedImage = ImageHelper.cropImage(image: self.image, cropRect: realCropRect)
        return croppedImage
    }
    
    func rotate() {
        
    }
    
    func reset() {
        scrollView.removeFromSuperview()
        dimmingView.removeFromSuperview()
        visualEffectView.removeFromSuperview()
        gridOverlayView.removeFromSuperview()
        angleDashboard.removeFromSuperview()
        
        cropBoxFrame = .zero
        
        viewStatus = .initial
        adaptForCropBox()
    }
}
