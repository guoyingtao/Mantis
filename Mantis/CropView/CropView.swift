//
//  CropView.swift
//  Mantis
//
//  Created by Echo on 10/20/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

protocol CropViewDelegate {
    func cropViewDidBecomeResettable(_ cropView: CropView)
    func cropViewDidBecomeNonResettable(_ cropView: CropView)
}

class CropView: UIView {
    let cropViewMinimumBoxSize: CGFloat = 42
    var minimumAspectRatio: CGFloat = 0
    let angleDashboardHeight: CGFloat = 50
    let hotAreaUnit = CGFloat(64)
    
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
    fileprivate var imageContainer: ImageContainer!
    fileprivate var cropMaskViewManager: CropMaskViewManager!
    
    fileprivate var angleDashboard: AngleDashboard!
    fileprivate var scrollView: CropScrollView!
    fileprivate var gridOverlayView: CropOverlayView!
    
    fileprivate var forCrop = true
    fileprivate var currentPoint: CGPoint?
    fileprivate var previousPoint: CGPoint?
    fileprivate var rotationCal: RotationCalculator?
    
    fileprivate var manualZoomed = false
    
    init(image: UIImage, imageStatus status: ImageStatus = ImageStatus()) {
        super.init(frame: CGRect.zero)
        self.image = image
        self.imageStatus = status
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func render(by viewStatus: CropViewStatus) {
        gridOverlayView.isHidden = false
        
        switch viewStatus {
        case .initial:
            setupUI()
        case .rotating:
            cropMaskViewManager.showVisualEffectBackground()
            gridOverlayView.isHidden = true
            angleDashboard.isHidden = true
        case .touchImage:
            cropMaskViewManager.showDimmingBackground()
            gridOverlayView.gridLineNumberType = .crop
            gridOverlayView.setGrid(hidden: false, animated: true)
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
            adaptAngleDashboardToCropBox()
            cropMaskViewManager.showVisualEffectBackground()
        }
    }
    
    private func setupUI() {
        setupScrollView()
        
        imageContainer = ImageContainer()
        imageContainer.image = image
        
        scrollView.addSubview(imageContainer)
        scrollView.imageContainer = imageContainer
        cropMaskViewManager = CropMaskViewManager(with: self)
        
        setGridOverlayView()
    }
    
    func adaptForCropBox() {
        cropBoxFrame = initialCropBoxRect
        cropOrignFrame = cropBoxFrame
        
        scrollView.frame = initialCropBoxRect
        scrollView.contentSize = initialCropBoxRect.size
        
        imageContainer.frame = scrollView.bounds
        imageContainer.center = CGPoint(x: scrollView.bounds.width/2, y: scrollView.bounds.height/2)
        setupAngleDashboard()
        
        // To do
        if aspectRatioLockEnabled {
            var cropBoxFrame = self.cropBoxFrame
            let scale = aspectRatio.width / aspectRatio.height
            let newWidth = cropBoxFrame.height / scale
            cropBoxFrame.origin.x += (cropBoxFrame.size.width - newWidth) / 2
            cropBoxFrame.size.width = newWidth
            self.cropBoxFrame = cropBoxFrame
            
            adjustUIForNewCrop() { [weak self] in
                self?.viewStatus = .betweenOperation
            }
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
        
        scrollView.delegate = self        
        addSubview(scrollView)
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
        
        var imageRefFrame = CGRect(x: imageContainer.frame.origin.x - 1, y: imageContainer.frame.origin.y - 1, width: imageContainer.frame.width + 2, height: imageContainer.frame.height + 2 )
        imageRefFrame = imageContainer.convert(imageRefFrame, to: self)
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
        let touchRect = cropBoxFrame.insetBy(dx: -hotAreaUnit / 2, dy: -hotAreaUnit / 2)
        return GeometryHelper.getCropEdge(forPoint: point, byTouchRect: touchRect, hotAreaUnit: hotAreaUnit)
    }
}

extension CropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageContainer
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewStatus = .touchImage
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        viewStatus = .touchImage
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        viewStatus = .betweenOperation
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        manualZoomed = true
        viewStatus = .betweenOperation
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        viewStatus = .betweenOperation
    }
}

extension CropView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if (gridOverlayView.frame.insetBy(dx: -hotAreaUnit,
                                       dy: -hotAreaUnit).contains(point) &&
            !gridOverlayView.frame.insetBy(dx: hotAreaUnit,
                                         dy: hotAreaUnit).contains(point)
        || angleDashboard.frame.contains(point)) {
            return self
        }
        
        if self.frame.contains(point) {
            return self.scrollView
        }
        
        return nil        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        viewStatus = .touchImage
        
        guard touches.count == 1, let touch = touches.first else {
            return
        }
        
        let point = touch.location(in: self)
        
        if checkIsAngleDashboardTouched(forPoint: point) {
            forCrop = false
            let rotationCenter = self.convert(gridOverlayView.center, to: self)
            rotationCal = RotationCalculator(midPoint: rotationCenter)
            currentPoint = point
            previousPoint = point
        } else {
            forCrop = true
            panOriginPoint = point
            cropOrignFrame = cropBoxFrame
            
            tappedEdge = cropEdge(forPoint: point)
            
            if tappedEdge != .none {
                viewStatus = .touchCropboxHandle
            }
        }
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
            if let radians = rotationCal?.getRotationRadians(byOldPoint: previousPoint!, andNewPoint: currentPoint!) {
                
                guard angleDashboard.rotateDialPlate(byRadians: radians) == true else {
                    return
                }
                
                imageStatus.degrees = angleDashboard.getRotationDegrees()
                let radians = imageStatus.getTotalRadians()
                
                scrollView.transform = CGAffineTransform(rotationAngle: radians)
                updatePosition(by: radians)
            }
            
            previousPoint = currentPoint
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if forCrop {
            if !cropOrignFrame.equalTo(cropBoxFrame) {
                adjustUIForNewCrop() {[weak self] in
                    self?.viewStatus = .betweenOperation                    
                }
            } else {
                viewStatus = .betweenOperation
            }
        } else {
            currentPoint = nil
            previousPoint = nil
            rotationCal = nil
            
            imageStatus.degrees = angleDashboard.getRotationDegrees()
            
            viewStatus = .betweenOperation
        }
        
        forCrop = true        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
    }
}

// Adjust UI
extension CropView {
    func adjustUIForNewCrop(completion: @escaping ()->Void) {
        let contentRect = contentBounds
        
        let scaleX: CGFloat
        let scaleY: CGFloat
        
        scaleX = contentRect.width / cropBoxFrame.size.width
        scaleY = contentRect.height / cropBoxFrame.size.height
        
        let scale = min(scaleX, scaleY)
        
        let newCropBounds = CGRect(x: 0, y: 0, width: cropBoxFrame.width * scale, height: cropBoxFrame.height * scale)
        
        let radians = imageStatus.getTotalRadians()
        
        // calculate the new bounds of scroll view
        let width = abs(cos(radians)) * newCropBounds.size.width + abs(sin(radians)) * newCropBounds.size.height
        let height = abs(sin(radians)) * newCropBounds.size.width + abs(cos(radians)) * newCropBounds.size.height
        
        // calculate the zoom area of scroll view
        var scaleFrame = cropBoxFrame
        if scaleFrame.width >= scrollView.contentSize.width {
            scaleFrame.size.width = scrollView.contentSize.width
        }
        if scaleFrame.height >= scrollView.contentSize.height {
            scaleFrame.size.height = scrollView.contentSize.height
        }
        
        let contentOffset = scrollView.contentOffset
        let contentOffsetCenter = CGPoint(x: (contentOffset.x + scrollView.bounds.width / 2),
                                          y: (contentOffset.y + scrollView.bounds.height / 2))
        
        
        scrollView.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        let newContentOffset = CGPoint(x: (contentOffsetCenter.x - scrollView.bounds.width / 2),
                                       y: (contentOffsetCenter.y - scrollView.bounds.height / 2))
        scrollView.contentOffset = newContentOffset
        
        let newCropBoxFrame = GeometryHelper.getIncribeRect(fromOutsideRect: contentRect, andInsideRect: self.cropBoxFrame)

        UIView.animate(withDuration: 0.25, animations: {[weak self] in
            guard let self = self else { return }
            self.cropBoxFrame = newCropBoxFrame
            
            let zoomRect = self.convert(scaleFrame,
                                                to: self.scrollView.imageContainer)
            self.scrollView.zoom(to: zoomRect, animated: false)
            self.scrollView.checkContentOffset()
        }) {_ in
            completion()
        }
        
        manualZoomed = true
    }

    fileprivate func updatePosition(by radians: CGFloat) {
        // position scroll view
        let width = abs(cos(radians)) * gridOverlayView.frame.width + abs(sin(radians)) * gridOverlayView.frame.height
        let height = abs(sin(radians)) * gridOverlayView.frame.width + abs(cos(radians)) * gridOverlayView.frame.height
        
        scrollView.updateLayout(byNewSize: CGSize(width: width, height: height))
        
        if !manualZoomed || scrollView.shouldScale() {
            scrollView.zoomScaleToBound()
            manualZoomed = false
        }
        
        scrollView.checkContentOffset()
    }
    
    fileprivate func updatePositionFor90Rotation(by radians: CGFloat) {
        // position scroll view
        let width = abs(cos(radians)) * gridOverlayView.frame.width + abs(sin(radians)) * gridOverlayView.frame.height
        let height = abs(sin(radians)) * gridOverlayView.frame.width + abs(cos(radians)) * gridOverlayView.frame.height
        
        let newSize: CGSize
        let scale: CGFloat
        if imageStatus.rotationType == .none || imageStatus.rotationType == .anticlockwise180 {
            newSize = CGSize(width: width, height: height)
        } else {
            newSize = CGSize(width: height, height: width)
        }
        
        scale = newSize.width / scrollView.bounds.width        
        scrollView.updateLayout(byNewSize: newSize)
        
        let newZoomScale = scrollView.zoomScale * scale
        scrollView.minimumZoomScale = newZoomScale
        scrollView.zoomScale = newZoomScale
        
        scrollView.checkContentOffset()
    }
}

// public api
extension CropView {
    
    func crop() -> UIImage? {
        let rect = imageContainer.convert(imageContainer.bounds,
                                                         to: self)
        let point = CGPoint(x: (rect.origin.x + rect.width / 2),
                            y: (rect.origin.y + rect.height / 2))
        let zeroPoint = CGPoint(x: frame.width / 2, y: gridOverlayView.center.y)
        
        var transform = CGAffineTransform.identity
        // translate
        let translation =  CGPoint(x: (point.x - zeroPoint.x), y: (point.y - zeroPoint.y))
        transform = transform.translatedBy(x: translation.x, y: translation.y)
        
        // rotate
        transform = transform.rotated(by: imageStatus.radians)
        
        // scale
        let t = imageContainer.transform
        let xScale: CGFloat = sqrt(t.a * t.a + t.c * t.c)
        let yScale: CGFloat = sqrt(t.b * t.b + t.d * t.d)
        transform = transform.scaledBy(x: xScale, y: yScale)
        
        guard let fixedImage = image.cgImageWithFixedOrientation() else {
            return nil
        }
            
        guard let imageRef = fixedImage.transformedImage(transform,
                                                       zoomScale: scrollView.zoomScale,
                                                       sourceSize: image.size,
                                                       cropSize: gridOverlayView.frame.size,
                                                       imageViewSize: imageContainer.bounds.size) else {
                                                        return nil
        }
        
        return UIImage(cgImage: imageRef)
    }
    
    func anticlockwiseRotate90() {
        viewStatus = .rotating
        
        var rect = gridOverlayView.frame
        rect.size.width = gridOverlayView.frame.height
        rect.size.height = gridOverlayView.frame.width
        
        let newRect = GeometryHelper.getIncribeRect(fromOutsideRect: contentBounds, andInsideRect: rect)
        
        let radian = -CGFloat.pi / 2
        let transfrom = scrollView.transform.rotated(by: radian)
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.cropBoxFrame = newRect
            self.scrollView.transform = transfrom
            self.updatePositionFor90Rotation(by: radian + self.imageStatus.radians)
        }) {[weak self] _ in
            guard let self = self else { return }
            self.imageStatus.zoomScale = self.scrollView.zoomScale
            self.imageStatus.anticlockwiseRotate90()
            self.viewStatus = .betweenOperation
        }
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
    
    fileprivate func setRotation(byRadians radians: CGFloat) {
        scrollView.transform = CGAffineTransform(rotationAngle: radians)
        updatePosition(by: radians)
        angleDashboard.rotateDialPlate(toRadians: radians, animated: false)
    }
    
    func setRotation(byDegrees degrees: CGFloat) {
        imageStatus.degrees = degrees
        let radians = degrees * CGFloat.pi / 180
        
        UIView.animate(withDuration: 0.5) {
            self.setRotation(byRadians: radians)
        }
    }
}
