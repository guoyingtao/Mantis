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
            cropMaskViewManager.adaptMaskTo(match: cropBoxFrame)
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
    
    fileprivate var cropMaskViewManager: CropMaskViewManager!
    
    fileprivate var angleDashboard: AngleDashboard!
    fileprivate var scrollView: CropScrollView!
    fileprivate var gridOverlayView: CropOverlayView!
    
    fileprivate var forCrop = true
    fileprivate var currentPoint: CGPoint?
    fileprivate var previousPoint: CGPoint?
    fileprivate var rotationCal: RotationCalculator?
    fileprivate var demoRotationCenterView: UIView?
    
    fileprivate var rotationCenter: CGPoint = .zero
    fileprivate var imageZoomScaleBeforeRotation: CGFloat = 1
    fileprivate var lastTouchedPoints: [CGPoint] = []
    
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
            cropMaskViewManager.showDimmingBackground()
        case .touchCropboxHandle:
            gridOverlayView.gridLineNumberType = .crop
            gridOverlayView.setGrid(hidden: false, animated: true)
            angleDashboard.isHidden = true
            cropMaskViewManager.showDimmingBackground()
        case .touchRotationBoard:
            gridOverlayView.gridLineNumberType = .rotate
            gridOverlayView.setGrid(hidden: false, animated: true)
            cropMaskViewManager.showDimmingBackground()
        case .betweenOperation:
            gridOverlayView.setGrid(hidden: true, animated: true)
            angleDashboard.isHidden = false
            cropMaskViewManager.showVisualEffectBackground()
        }
    }
    
    private func setupUI() {
        setupScrollView()
        
        imageView = createImageView(image: image)
        imageViewContainer = UIView()
        imageViewContainer.addSubview(imageView)
        scrollView.addSubview(imageViewContainer)
        
        cropMaskViewManager = CropMaskViewManager(with: self)
        setGridOverlayView()
    }
    
    private func initialSetup() {
        viewStatus = .initial
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
        
        let boardLength = gridOverlayView.frame.width * 0.8
        let x:CGFloat = 0
        let y = gridOverlayView.frame.maxY
        angleDashboard = AngleDashboard(frame: CGRect(x: x, y: y, width: boardLength, height: angleDashboardHeight))
        angleDashboard.center.x = gridOverlayView.center.x
        addSubview(angleDashboard)
    }
    
    private func adaptAngleDashboardToCropBox() {
        angleDashboard.frame.origin.y = gridOverlayView.frame.maxY
    }
    
    fileprivate func updateCropBoxFrame(withTouchPoint point: CGPoint) {
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
    
    fileprivate func checkIsAngleDashboardTouched(forPoint point: CGPoint) -> Bool {
        let contains = angleDashboard.frame.contains(point)
        
        if contains == true {
            viewStatus = .touchRotationBoard
        }
        
        return contains
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
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewStatus = .touchImage
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        viewStatus = .touchImage
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageZoomScaleBeforeRotation = imageView.transform.scaleX
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        viewStatus = .betweenOperation
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        viewStatus = .betweenOperation
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        viewStatus = .betweenOperation
    }
}

extension CropView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        viewStatus = .touchImage
        
        guard touches.count == 1, let touch = touches.first else {
            return
        }
        
        let point = touch.location(in: self)
        
        if checkIsAngleDashboardTouched(forPoint: point) {
            forCrop = false
            rotationCenter = self.convert(gridOverlayView.center, to: self)
            
            rotationCal = RotationCalculator(midPoint: rotationCenter)
            currentPoint = point
            previousPoint = point
            
            setImageViewAnchor(byRotationCenter: rotationCenter)
        } else {
            forCrop = true
            panOriginPoint = point
            cropOrignFrame = cropBoxFrame
            
            checkTouchEdge(forPoint: point)
        }

//        if let touch = touches.first {
//            if !checkIsAngleDashboardTouched(forPoint: point) {
//                checkTouchEdge(forPoint: point)
//            }
//        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard touches.count == 1, let touch = touches.first else {
            return
        }

        
        let point = touch.location(in: self)
        
        if forCrop {
            updateCropBoxFrame(withTouchPoint: point)
        } else {
            currentPoint = point
            if let rotation = rotationCal?.getRotation(byOldPoint: previousPoint!, andNewPoint: currentPoint!) {
                let points = GeometryHelper.getOverSteppedCornerPoints(from: imageView, andeInnerView: gridOverlayView)
                
                guard angleDashboard.rotateDialPlate(by: rotation) == true else {
                    return
                }
                
                if points.count > 0 {
                    lastTouchedPoints = points
                    setImageViewAnchor(byRotationCenter: rotationCenter)
                    resetImageToCoverCropBox(by: points, and: rotation)
                } else {
                    if imageView.transform.scaleX > imageZoomScaleBeforeRotation {
                        resetImageToCoverCropBox(by: lastTouchedPoints, and: rotation, isZoomIn: false)
                    }
                }
                
                imageView.transform = imageView.transform.rotated(by: rotation)
            }
            
            previousPoint = currentPoint
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
//        viewStatus = .betweenOperation
        
        demoRotationCenterView?.removeFromSuperview()
        let anchorPoint = CGPoint(x: 0.5, y: 0.5)
        imageView.setAnchorPoint(anchorPoint: anchorPoint)
        if forCrop {
            moveCroppedContentToCenter(animated: true)
        } else {
            currentPoint = nil
            previousPoint = nil
            rotationCal = nil
            
            let angle = angleDashboard.getRotationAngle()
            imageStatus.angle = angle
        }
        
        forCrop = true
        viewStatus = .betweenOperation
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
    }
}

extension CropView {
    fileprivate func checkTouchEdge(forPoint point: CGPoint) {
        tappedEdge = cropEdge(forPoint: point)
        
        if tappedEdge != .none {
            viewStatus = .touchCropboxHandle
        }
    }
    
    fileprivate func setImageViewAnchor(by point: CGPoint) {
        // Do not use imageView frame because the frame will change after rotation!
        let anchorPoint = CGPoint(x: point.x / imageView.bounds.width, y: point.y / imageView.bounds.height)
        
        imageView.setAnchorPoint(anchorPoint: anchorPoint)
    }
    
    fileprivate func setImageViewAnchor(byRotationCenter rotationCenter: CGPoint) {
        let rotationCenterOnImage = self.convert(rotationCenter, to: imageView)
        setImageViewAnchor(by: rotationCenterOnImage)
    }
    
    private func resetImageToCoverCropBox(by points: [CGPoint], and rotation: CGFloat, isZoomIn: Bool = true) {
        guard points.count > 0 else { return }
        
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        for point in points {
            x += point.x
            y += point.y
        }
        
        x /= CGFloat(points.count)
        y /= CGFloat(points.count)
        
        let a = abs(gridOverlayView.bounds.width * sin(rotation))
        let b = abs(gridOverlayView.bounds.height * cos(rotation))
        let c = abs(gridOverlayView.bounds.width * cos(rotation))
        let d = abs(gridOverlayView.bounds.height * sin(rotation))
        var scale = max((a + b) / gridOverlayView.bounds.height, (c + d) / gridOverlayView.bounds.width)
        
        scale = isZoomIn ? scale : 1.0 / scale
        imageView.transform = imageView.transform.scaledBy(x: scale, y: scale)
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
                self?.viewStatus = .betweenOperation
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
    
    func clockwiseRotate90() {
        imageStatus.clockwiseRotate90()
        let rotation = CGFloat.pi * 0.5
        imageView.transform = imageView.transform.rotated(by: rotation)
    }
    
    func reset() {
        scrollView.removeFromSuperview()
        cropMaskViewManager.removeMaskViews()
        gridOverlayView.removeFromSuperview()
        angleDashboard.removeFromSuperview()
        
        cropBoxFrame = .zero
        
        viewStatus = .initial
        imageStatus.reset()
        adaptForCropBox()
    }
}
