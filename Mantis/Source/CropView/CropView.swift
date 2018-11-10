//
//  CropView.swift
//  Mantis
//
//  Created by Echo on 10/20/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

protocol CropViewDelegate: class {
    func cropViewDidBecomeResettable(_ cropView: CropView)
    func cropViewDidBecomeNonResettable(_ cropView: CropView)
}

class CropView: UIView {
    fileprivate let cropViewMinimumBoxSize: CGFloat = 42
    fileprivate let minimumAspectRatio: CGFloat = 0
    fileprivate let angleDashboardHeight: CGFloat = 60
    fileprivate let hotAreaUnit: CGFloat = 64
    fileprivate let cropViewPadding:CGFloat = 14.0
    
    fileprivate var viewStatus: CropViewStatus = .initial {
        didSet {
            render(by: viewStatus)
        }
    }
    
    var viewModel: CropViewModel!
    
    fileprivate var panOriginPoint = CGPoint.zero
    
    fileprivate var cropBoxFrame = CGRect.zero {
        didSet {
            if oldValue.equalTo(cropBoxFrame) { return }
            
            gridOverlayView.frame = cropBoxFrame
            cropMaskViewManager.adaptMaskTo(match: cropBoxFrame)
        }
    }
    
    weak var delegate: CropViewDelegate? {
        didSet {
            checkImageStatusChanged()
        }
    }
    
    fileprivate var cropOrignFrame = CGRect.zero
    fileprivate var tappedEdge = CropViewOverlayEdge.none
    
    var aspectRatioLockEnabled = false
    
    fileprivate var image: UIImage!
    lazy var imageRatioH = {
        return image.ratioH()
    }()
    
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
    
    deinit {
        print("CropView deinit.")
    }
    
    init(image: UIImage, viewModel: CropViewModel = CropViewModel()) {
        super.init(frame: CGRect.zero)
        self.image = image
        self.viewModel = viewModel
        initalRender()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initalRender() {
        setupUI()
        checkImageStatusChanged()
    }
    
    private func render(by viewStatus: CropViewStatus) {
        gridOverlayView.isHidden = false
        
        switch viewStatus {
        case .initial:
            initalRender()
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
            checkImageStatusChanged()
        }
    }
    
    private func isTheSamePoint(p1: CGPoint, p2: CGPoint) -> Bool {
        if abs(p1.x - p2.x) > CGFloat.ulpOfOne { return false }
        if abs(p1.y - p2.y) > CGFloat.ulpOfOne { return false }
        
        return true
    }
    
    private func imageStatusChanged() -> Bool {
        if viewModel.getTotalRadians() != 0 { return true }
        if !isTheSamePoint(p1: getImageLeftTopAnchorPoint(), p2: .zero) {
            return true
        }
        
        if !isTheSamePoint(p1: getImageRightBottomAnchorPoint(), p2: CGPoint(x: 1, y: 1)) {
            return true
        }
        
        return false
    }
    
    private func checkImageStatusChanged() {
        if imageStatusChanged() {
            delegate?.cropViewDidBecomeResettable(self)
        } else {
            delegate?.cropViewDidBecomeNonResettable(self)
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
    
    func resetUIFrame() {
        cropBoxFrame = getInitialCropBoxRect()
        cropOrignFrame = cropBoxFrame
        
        scrollView.transform = .identity
        scrollView.resetBy(rect: cropBoxFrame)
        
        imageContainer.frame = scrollView.bounds
        imageContainer.center = CGPoint(x: scrollView.bounds.width/2, y: scrollView.bounds.height/2)
        
        setupAngleDashboard()
        
        if aspectRatioLockEnabled {
            setFixedRatioCropBox()
        }
    }
    
    func adaptForCropBox() {
        resetUIFrame()
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
        
        let boardLength = min(bounds.width, bounds.height) * 0.6
        angleDashboard = AngleDashboard(frame: CGRect(x: 0, y: 0, width: boardLength, height: angleDashboardHeight))
        addSubview(angleDashboard)
        
        angleDashboard.rotateDialPlate(byRadians: viewModel.radians)
        
        adaptAngleDashboardToCropBox()
    }
    
    private func adaptAngleDashboardToCropBox() {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            angleDashboard.transform = CGAffineTransform(rotationAngle: 0)
            angleDashboard.frame.origin.x = gridOverlayView.frame.origin.x +  (gridOverlayView.frame.width - angleDashboard.frame.width) / 2
            angleDashboard.frame.origin.y = gridOverlayView.frame.maxY
        } else if UIApplication.shared.statusBarOrientation == .landscapeLeft {
            angleDashboard.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            angleDashboard.frame.origin.x = gridOverlayView.frame.maxX
            angleDashboard.frame.origin.y = gridOverlayView.frame.origin.y + (gridOverlayView.frame.height - angleDashboard.frame.height) / 2
        } else if UIApplication.shared.statusBarOrientation == .landscapeRight {
            angleDashboard.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            angleDashboard.frame.origin.x = gridOverlayView.frame.minX - angleDashboard.frame.width
            angleDashboard.frame.origin.y = gridOverlayView.frame.origin.y + (gridOverlayView.frame.height - angleDashboard.frame.height) / 2
        }
    }
    
    fileprivate func updateCropBoxFrame(withTouchPoint point: CGPoint) {
        let contentFrame = getContentBounds()
        
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
        if !decelerate {
            viewStatus = .betweenOperation
        }
    }
}

extension CropView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let p = self.convert(point, to: self)
        
        if (gridOverlayView.frame.insetBy(dx: -hotAreaUnit,
                                       dy: -hotAreaUnit).contains(p) &&
            !gridOverlayView.frame.insetBy(dx: hotAreaUnit,
                                         dy: hotAreaUnit).contains(p)
        || angleDashboard.frame.contains(p)) {
            return self
        }
        
        if self.bounds.contains(p) {
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
                
                viewModel.degrees = angleDashboard.getRotationDegrees()
                rotateScrollView()
            }
            
            previousPoint = currentPoint
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if forCrop {
            if !cropOrignFrame.equalTo(cropBoxFrame) {
                let contentRect = getContentBounds()
                adjustUIForNewCrop(contentRect: contentRect) {[weak self] in
                    self?.viewStatus = .betweenOperation                    
                }
            } else {
                viewStatus = .betweenOperation
            }
        } else {
            currentPoint = nil
            previousPoint = nil
            rotationCal = nil
            viewModel.degrees = angleDashboard.getRotationDegrees()
            viewStatus = .betweenOperation
        }
        
        forCrop = true        
    }
}

// Adjust UI
extension CropView {
    private func rotateScrollView() {
        let radians = viewModel.getTotalRadians()
        self.scrollView.transform = CGAffineTransform(rotationAngle: radians)
        self.updatePosition(by: radians)
    }
    
    private func getInitialCropBoxRect() -> CGRect {
        guard let image = image else { return .zero }
        guard image.size.width > 0 && image.size.height > 0 else { return .zero }
        
        let outsideRect = getContentBounds()
        let insideRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        return GeometryHelper.getIncribeRect(fromOutsideRect: outsideRect, andInsideRect: insideRect)
    }
    
    fileprivate func getContentBounds() -> CGRect {
        let rect = self.bounds
        var contentRect = CGRect.zero
        
        if UIApplication.shared.statusBarOrientation.isPortrait {
            contentRect.origin.x = rect.origin.x + cropViewPadding
            contentRect.origin.y = rect.origin.y + cropViewPadding
            
            contentRect.size.width = rect.width - 2 * cropViewPadding
            contentRect.size.height = rect.height - 2 * cropViewPadding - angleDashboardHeight
        } else if UIApplication.shared.statusBarOrientation.isLandscape {
            contentRect.size.width = rect.width - 2 * cropViewPadding - angleDashboardHeight
            contentRect.size.height = rect.height - 2 * cropViewPadding
            
            contentRect.origin.y = rect.origin.y + cropViewPadding
            if UIApplication.shared.statusBarOrientation == .landscapeLeft {
                contentRect.origin.x = rect.origin.x + cropViewPadding
            } else {
                contentRect.origin.x = rect.origin.x + cropViewPadding + angleDashboardHeight
            }
        }
        
        return contentRect
    }

    fileprivate func getImageLeftTopAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.cropLeftTopOnImage
        }
        
        let lt = gridOverlayView.convert(CGPoint(x: 0, y: 0), to: imageContainer)
        let point = CGPoint(x: lt.x / imageContainer.bounds.width, y: lt.y / imageContainer.bounds.height)
        return point
    }
    
    fileprivate func getImageRightBottomAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.cropRightBottomOnImage
        }

        let rb = gridOverlayView.convert(CGPoint(x: gridOverlayView.bounds.width, y: gridOverlayView.bounds.height), to: imageContainer)
        let point = CGPoint(x: rb.x / imageContainer.bounds.width, y: rb.y / imageContainer.bounds.height)
        return point
    }
    
    fileprivate func saveAnchorPoints() {
        viewModel.cropLeftTopOnImage = getImageLeftTopAnchorPoint()
        viewModel.cropRightBottomOnImage = getImageRightBottomAnchorPoint()
    }
    
    fileprivate func adjustUIForNewCrop(contentRect:CGRect, completion: @escaping ()->Void) {
        
        let scaleX: CGFloat
        let scaleY: CGFloat
        
        scaleX = contentRect.width / cropBoxFrame.size.width
        scaleY = contentRect.height / cropBoxFrame.size.height
        
        let scale = min(scaleX, scaleY)
        
        let newCropBounds = CGRect(x: 0, y: 0, width: cropBoxFrame.width * scale, height: cropBoxFrame.height * scale)
        
        let radians = viewModel.getTotalRadians()
        
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
        let width = abs(cos(radians)) * gridOverlayView.frame.width + abs(sin(radians)) * gridOverlayView.frame.height
        let height = abs(sin(radians)) * gridOverlayView.frame.width + abs(cos(radians)) * gridOverlayView.frame.height
        
        let newSize: CGSize
        let scale: CGFloat
        if viewModel.rotationType == .none || viewModel.rotationType == .counterclockwise180 {
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
    
    fileprivate func updateScrollViewLayout(by cropBox: CGRect) {
        let radians = viewModel.getTotalRadians()
        let width = abs(cos(radians)) * cropBox.width + abs(sin(radians)) * cropBox.height
        let height = abs(sin(radians)) * cropBox.width + abs(cos(radians)) * cropBox.height
        
        let newSize = CGSize(width: width, height: height)
        scrollView.updateLayout(byNewSize: newSize)
        scrollView.checkContentOffset()
    }
}

// public api
extension CropView {    
    func crop() -> UIImage? {
        let rect = imageContainer.convert(imageContainer.bounds,
                                                         to: self)
        let point = rect.center
        let zeroPoint = gridOverlayView.center
        
        var transform = CGAffineTransform.identity
        // translate
        let translation =  CGPoint(x: (point.x - zeroPoint.x), y: (point.y - zeroPoint.y))
        transform = transform.translatedBy(x: translation.x, y: translation.y)
        
        // rotate
        transform = transform.rotated(by: viewModel.getTotalRadians())
        
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
    
    func handleRotate() {
        resetUIFrame()
        rotateScrollView()

        if viewModel.cropRightBottomOnImage != .zero {
            var lt = CGPoint(x: viewModel.cropLeftTopOnImage.x * imageContainer.bounds.width, y: viewModel.cropLeftTopOnImage.y * imageContainer.bounds.height)
            var rb = CGPoint(x: viewModel.cropRightBottomOnImage.x * imageContainer.bounds.width, y: viewModel.cropRightBottomOnImage.y * imageContainer.bounds.height)
            
            lt = imageContainer.convert(lt, to: self)
            rb = imageContainer.convert(rb, to: self)
            
            let rect = CGRect(origin: lt, size: CGSize(width: rb.x - lt.x, height: rb.y - lt.y))
            cropBoxFrame = rect
            
            let contentRect = getContentBounds()
            
            adjustUIForNewCrop(contentRect: contentRect) { [weak self] in
                self?.adaptAngleDashboardToCropBox()
                self?.viewStatus = .betweenOperation
            }
        }
    }
    
    func counterclockwiseRotate90() {
        viewStatus = .rotating
        
        var rect = gridOverlayView.frame
        rect.size.width = gridOverlayView.frame.height
        rect.size.height = gridOverlayView.frame.width
        
        let newRect = GeometryHelper.getIncribeRect(fromOutsideRect: getContentBounds(), andInsideRect: rect)
        
        let radian = -CGFloat.pi / 2
        let transfrom = scrollView.transform.rotated(by: radian)
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.cropBoxFrame = newRect
            self.scrollView.transform = transfrom
            self.updatePositionFor90Rotation(by: radian + self.viewModel.radians)
        }) {[weak self] _ in
            guard let self = self else { return }
            self.viewModel.counterclockwiseRotate90()
            self.viewStatus = .betweenOperation
        }
    }
    
    func reset() {
        scrollView.removeFromSuperview()
        cropMaskViewManager.removeMaskViews()
        gridOverlayView.removeFromSuperview()
        angleDashboard.removeFromSuperview()
        
        cropBoxFrame = .zero
        aspectRatioLockEnabled = false
                
        viewModel.reset()
        
        viewStatus = .initial
        resetUIFrame()
    }
    
    func prepareForDeviceRotation() {
        viewStatus = .rotating
        saveAnchorPoints()
    }
    
    fileprivate func setRotation(byRadians radians: CGFloat) {
        scrollView.transform = CGAffineTransform(rotationAngle: radians)
        updatePosition(by: radians)
        angleDashboard.rotateDialPlate(toRadians: radians, animated: false)
    }
    
    func setRotation(byDegrees degrees: CGFloat) {
        viewModel.degrees = degrees
        let radians = degrees * CGFloat.pi / 180
        
        UIView.animate(withDuration: 0.5) {
            self.setRotation(byRadians: radians)
        }
    }
    
    func setFixedRatioCropBox() {
        var cropBoxFrame = getInitialCropBoxRect()
        let center = cropBoxFrame.center
        
        if viewModel.aspectRatio > (cropBoxFrame.width / cropBoxFrame.height) {
            cropBoxFrame.size.height = cropBoxFrame.width / viewModel.aspectRatio
        } else {
            cropBoxFrame.size.width = cropBoxFrame.height * viewModel.aspectRatio
        }
        
        cropBoxFrame.origin.x = center.x - cropBoxFrame.width / 2
        cropBoxFrame.origin.y = center.y - cropBoxFrame.height / 2
        
        self.cropBoxFrame = cropBoxFrame
        
        let contentRect = getContentBounds()
        adjustUIForNewCrop(contentRect: contentRect) { [weak self] in
            self?.viewStatus = .betweenOperation
        }
        
        adaptAngleDashboardToCropBox()
    }

    func getRatioType(byImageIsOriginalisHorizontal isHorizontal: Bool) -> RatioType {
        return viewModel.getRatioType(byImageIsOriginalHorizontal: isHorizontal)
    }
    
    func getImageRatioH() -> Double {
        if viewModel.rotationType == .none || viewModel.rotationType == .counterclockwise180 {
            return Double(image.ratioH())
        } else {
            return Double(1/image.ratioH())
        }
    }
}
