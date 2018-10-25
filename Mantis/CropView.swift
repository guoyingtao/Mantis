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
    
    fileprivate var editing = false {
        didSet {
            if editing == oldValue { return }
            set(editing: editing, resetCropbox: false, animated: false)
        }
    }
    
    fileprivate var imageCropFrame: CGRect {
        get {
            let imageSize = self.imageSize()
            let contentSize = scrollView.contentSize
            let contentOffset = scrollView.contentOffset
            let edgeInsets = scrollView.contentInset
            
            let scale = min(imageSize.width / contentSize.width, imageSize.height / contentSize.height)
            
            var frame = CGRect.zero
            // Calculate the normalized origin
            frame.origin.x = floor((floor(contentOffset.x) + edgeInsets.left) * (imageSize.width / contentSize.width))
            frame.origin.x = max(0, frame.origin.x)
            
            frame.origin.y = floor((floor(contentOffset.y) + edgeInsets.top) * (imageSize.height / contentSize.height))
            frame.origin.y = max(0, frame.origin.y)
            
            // Calculate the normalized width
            frame.size.width = ceil(cropBoxFrame.width * scale)
            frame.size.width = min(imageSize.width, frame.size.width)
            
            // Calculate normalized height
            if (floor(cropBoxFrame.width) == floor(cropBoxFrame.height)) {
                frame.size.height = frame.size.width
            } else {
                frame.size.height = ceil(cropBoxFrame.height * scale)
                frame.size.height = min(imageSize.height, frame.height)
            }
            frame.size.height = min(imageSize.height, frame.size.height)
            
            return frame
        }
        
        set {
            guard initialSetupPerformed == false else {
                restoreImageCropFrame = imageCropFrame
                return
            }
            
            updateTo(imageCropframe: imageCropFrame)
        }
    }
    
    var imageViewFrame: CGRect {
        get {
            var frame = CGRect.zero
            frame.origin.x = -scrollView.contentOffset.x
            frame.origin.y = -scrollView.contentOffset.y
            frame.size = scrollView.contentSize
            return frame;
        }
    }
    
    var delegate: CropViewDelegate?
    
    var canBeReset: Bool = true {
        didSet {
            if canBeReset == oldValue {
                return
            }
            
            if canBeReset {
                delegate?.cropViewDidBecomeResettable(self)
            } else {
                delegate?.cropViewDidBecomeNonResettable(self)
            }
        }
    }
    
    fileprivate var aspectRatioLockDimensionSwapEnabled = false
    fileprivate var rotateAnimationInProgress = false
    fileprivate var gridOverlayHidden = true
    fileprivate var croppingViewsHidden = true
    fileprivate var cropBoxResizeEnabled = true
    fileprivate var initialSetupPerformed = false
    fileprivate var cropOrignFrame = CGRect.zero
    fileprivate var tappedEdge = CropViewOverlayEdge.none
    
    fileprivate var angle = 0 {
        didSet {
            var newAngle = angle
            
            if newAngle % 90 != 0 {
                newAngle = 0
            }
            
            if initialSetupPerformed == false {
                restoreAngle = newAngle
                return
            }
            
            // Negative values are allowed, so rotate clockwise or counter clockwise depending
            // on direction
            if (newAngle >= 0) {
                while (labs(self.angle) != labs(newAngle)) {
                    rotateImageNinetyDegrees(animated: false, clockwise: true)
                }
            }
            else {
                while (-labs(self.angle) != -labs(newAngle)) {
                    rotateImageNinetyDegrees(animated: false, clockwise: false)
                }
            }

        }
    }
    
    fileprivate var originalCropBoxSize = CGSize.zero
    fileprivate var originalContentOffset = CGPoint.zero
    
    fileprivate var rotationContentOffset = CGPoint.zero
    fileprivate var rotationContentSize = CGSize.zero
    fileprivate var rotationBoundFrame = CGRect.zero
    
    fileprivate var restoreAngle = 0
    fileprivate var cropBoxLastEditedSize = CGSize.zero
    fileprivate var cropBoxLastEditedAngle = 0
    fileprivate var cropBoxLastEditedZoomScale = CGFloat(0)
    fileprivate var cropBoxLastEditedMinZoomScale = CGFloat(0)
    
    fileprivate var restoreImageCropFrame = CGRect.zero
    
    fileprivate var cropViewPadding:CGFloat = 14.0
    fileprivate var maximumZoomScale:CGFloat = 15.0
    fileprivate var minimumZoomScale:CGFloat = 15.0
    
    fileprivate var aspectRatio = CGSize(width: 4.0, height: 3.0)
    fileprivate var aspectRatioLockEnabled = false
    
    private lazy var initialCropBoxRect: CGRect = {
        guard let image = image else { return .zero }
        guard image.size.width > 0 && image.size.height > 0 else { return .zero }
        
        let outsideRect = contentBounds
        let insideRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        return GeometryTools.getIncribeRect(fromOutsideRect: outsideRect, andInsideRect: insideRect)
    } ()
    
    fileprivate var imageView: UIImageView!
    fileprivate var imageViewContainer: UIView!
    fileprivate var dimmingView: CropDimmingView!
    fileprivate var visualEffectView: CropVisualEffectView!
    fileprivate var angleDashboard: AngleDashboard!
    fileprivate var image: UIImage!
    fileprivate var scrollView: CropScrollView!
    fileprivate var gridOverlayView: CropOverlayView!
    fileprivate var gridPanGestureRecognizer: UIPanGestureRecognizer!

    
    init(image: UIImage) {
        super.init(frame: CGRect.zero)
        self.image = image
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func reset() {
        scrollView.removeFromSuperview()
        dimmingView.removeFromSuperview()
        visualEffectView.removeFromSuperview()
        gridOverlayView.removeFromSuperview()
        angleDashboard.removeFromSuperview()
        
        cropBoxFrame = .zero
        
        setupUI()
        adaptForCropBox()
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
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }
    
    private func setup() {
        setupUI()
        setupGestures()
    }
    
    @objc func handleDoubleTap(recognizer: UIPanGestureRecognizer) {
        reset()
    }
    
    func adaptForCropBox() {
        print("initialCropBoxRect is \(initialCropBoxRect)")
        cropBoxFrame = initialCropBoxRect
        cropOrignFrame = cropBoxFrame
        scrollView.frame = contentBounds
        scrollView.contentSize = contentBounds.size
        scrollView.backgroundColor = .blue
        imageViewContainer.frame = scrollView.bounds
        imageView.frame = initialCropBoxRect
        imageView.center = CGPoint(x: imageViewContainer.bounds.width/2, y: imageViewContainer.bounds.height/2)
        setupAngleDashboard()
    }
    
    private func setupScrollView() {
        scrollView = CropScrollView(frame: bounds)
        scrollView.touchesBegan = { [weak self] in
            self?.showDimmingBackground()
        }
        scrollView.touchesEnded = { [weak self] in
            self?.showVisualEffectBackground()
        }
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 15.0
        scrollView.zoomScale = scrollView.minimumZoomScale
        
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
    
    fileprivate func prepareforRotation() {
        rotationContentOffset = scrollView.contentOffset
        rotationContentSize = scrollView.contentSize
        rotationBoundFrame = contentBounds
    }
    
    fileprivate func performRelayoutForRotation() {
        let contentFrame = contentBounds
        let scale = min(contentFrame.width / cropBoxFrame.width, contentFrame.height / cropBoxFrame.height)
        scrollView.minimumZoomScale = scale
        scrollView.zoomScale = scale
        
        //Work out the centered, upscaled version of the crop rectangle
        cropBoxFrame.size.width = floor(contentFrame.width * scale)
        cropBoxFrame.size.height = floor(contentFrame.height * scale)
        cropBoxFrame.origin.x = floor(contentFrame.origin.x + (contentFrame.width - cropBoxFrame.width) * 0.5)
        cropBoxFrame.origin.y = floor(contentFrame.origin.y + (contentFrame.height - cropBoxFrame.height) * 0.5)
        
        captureStateForImageRotation()
        
        //Work out the center point of the content before we rotated
        let oldMidPoint = CGPoint(x: rotationBoundFrame.midX, y: rotationBoundFrame.midY)
        let contentCenter = CGPoint(x: rotationContentOffset.x + oldMidPoint.x, y: rotationContentOffset.y + oldMidPoint.y)
        
        //Normalize it to a percentage we can apply to different sizes
        var normalizedCenter = CGPoint.zero
        normalizedCenter.x = contentCenter.x / rotationContentSize.width
        normalizedCenter.y = contentCenter.y / rotationContentSize.height

        //Work out the new content offset by applying the normalized values to the new layout
        let newMidPoint = CGPoint(x: contentFrame.midX, y: contentFrame.midY)
        var translatedContentOffset = CGPoint.zero
        translatedContentOffset.x = scrollView.contentSize.width * normalizedCenter.x
        translatedContentOffset.y = scrollView.contentSize.height * normalizedCenter.y
        
        var offset = CGPoint.zero
        offset.x = floor(translatedContentOffset.x - newMidPoint.x)
        offset.y = floor(translatedContentOffset.y - newMidPoint.y)

        //Make sure it doesn't overshoot the top left corner of the crop box
        offset.x = max(-scrollView.contentInset.left, offset.x)
        offset.y = max(-scrollView.contentInset.top, offset.y)

        //Nor undershoot the bottom right corner
        var maximumOffset = CGPoint.zero
        maximumOffset.x = (bounds.size.width - scrollView.contentInset.right) + scrollView.contentSize.width
        maximumOffset.y = (bounds.size.height - scrollView.contentInset.bottom) + scrollView.contentSize.height
        offset.x = min(offset.x, maximumOffset.x)
        offset.y = min(offset.y, maximumOffset.y)
        scrollView.contentOffset = offset
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
        
        var info = UpdateCropBoxFrameInfo(false, false, false, false)
        
        let newCropBoxFrame: CGRect
        if aspectRatioLockEnabled {
            var cropBoxLockedAspectFrameUpdater = CropBoxLockedAspectFrameUpdater(tappedEdge: tappedEdge, contentFrame: contentFrame, cropOriginFrame: cropOrignFrame, cropBoxFrame: cropBoxFrame)
            let aspectInfo = cropBoxLockedAspectFrameUpdater.updateCropBoxFrame(xDelta: xDelta, yDelta: yDelta)
            info.aspectHorizontal = aspectInfo.aspectHorizontal
            info.aspectVertical = aspectInfo.aspectVertical
            
            newCropBoxFrame = cropBoxLockedAspectFrameUpdater.cropBoxFrame
        } else {
            var cropBoxFreeAspectFrameUpdater = CropBoxFreeAspectFrameUpdater(tappedEdge: tappedEdge, contentFrame: contentFrame, cropOriginFrame: cropOrignFrame, cropBoxFrame: cropBoxFrame)
            let clampInfo = cropBoxFreeAspectFrameUpdater.updateCropBoxFrame(xDelta: xDelta, yDelta: yDelta)
            info.clampMinFromLeft = clampInfo.clampMinFromLeft
            info.clampMinFromTop = clampInfo.clampMinFromTop
            
            newCropBoxFrame = cropBoxFreeAspectFrameUpdater.cropBoxFrame
        }
        
        cropBoxFrame = newCropBoxFrame
        
//        var imageRefFrame = CGRect(x: imageView.frame.origin.x - 1, y: imageView.frame.origin.y - 1, width: imageView.frame.width + 2, height: imageView.frame.height + 2 )
//        imageRefFrame = imageView.convert(imageRefFrame, to: self)
//        if imageRefFrame.contains(newCropBoxFrame) {
//            cropBoxFrame = newCropBoxFrame
//        }
    }

    fileprivate func updateTo(imageCropframe: CGRect) {
        //Convert the image crop frame's size from image space to the screen space
        let minimumSize = scrollView.minimumZoomScale
        let scaledOffset = CGPoint(x: imageCropframe.origin.x * minimumSize, y: imageCropframe.origin.y * minimumSize)
        let scaledCropSize = CGSize(width: imageCropframe.size.width * minimumSize, height: imageCropframe.size.height * minimumSize)
        
        // Work out the scale necessary to upscale the crop size to fit the content bounds of the crop bound
        let bounds = contentBounds
        let scale = min(bounds.size.width / scaledCropSize.width, bounds.size.height / scaledCropSize.height)
        
        // Zoom into the scroll view to the appropriate size
        scrollView.zoomScale = scrollView.minimumZoomScale * scale;
        
        // Work out the size and offset of the upscaled crop box
        var frame = CGRect.zero
        frame.size = CGSize(width: scaledCropSize.width * scale, height: scaledCropSize.height * scale)
        
        //set the crop box
        var cropBoxFrame = CGRect.zero
        cropBoxFrame.size = frame.size;
        cropBoxFrame.origin.x = bounds.midX - (frame.size.width * 0.5)
        cropBoxFrame.origin.y = bounds.midY - (frame.size.height * 0.5)
        self.cropBoxFrame = cropBoxFrame
        
        frame.origin.x = (scaledOffset.x * scale) - scrollView.contentInset.left
        frame.origin.y = (scaledOffset.y * scale) - scrollView.contentInset.top
        scrollView.contentOffset = frame.origin
    }
    
    fileprivate func update(toImageCropFrame imageCropframe: CGRect) {
        //Convert the image crop frame's size from image space to the screen space
        let minimumSize = scrollView.minimumZoomScale;
        let scaledOffset = CGPoint(x: imageCropframe.origin.x * minimumSize, y: imageCropframe.origin.y * minimumSize)
        let scaledCropSize = CGSize(width: imageCropframe.size.width * minimumSize, height: imageCropframe.size.height * minimumSize)
    
        // Work out the scale necessary to upscale the crop size to fit the content bounds of the crop bound
        let contentFrame = contentBounds
        let scale = min(contentFrame.width / scaledCropSize.width, contentFrame.height / scaledCropSize.height)
        
        // Zoom into the scroll view to the appropriate size
        scrollView.zoomScale = scrollView.minimumZoomScale * scale
        
        // Work out the size and offset of the upscaled crop box
        var frame = CGRect.zero
        frame.size = CGSize(width: scaledCropSize.width * scale, height: scaledCropSize.height * scale)
        
        //set the crop box
        var cropBoxFrame = CGRect.zero
        cropBoxFrame.size = frame.size;
        cropBoxFrame.origin.x = contentFrame.midX - (frame.size.width * 0.5);
        cropBoxFrame.origin.y = contentFrame.midY - (frame.size.height * 0.5);
        
        frame.origin.x = (scaledOffset.x * scale) - scrollView.contentInset.left
        frame.origin.y = (scaledOffset.y * scale) - scrollView.contentInset.top
        scrollView.contentOffset = frame.origin
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
    
    fileprivate func setCropBox(panResizeEnabled: Bool) {
        cropBoxResizeEnabled = panResizeEnabled
        gridPanGestureRecognizer.isEnabled = cropBoxResizeEnabled
    }
    
    fileprivate func cropBoxAspectRatioIsPortrait() -> Bool {
        return cropBoxFrame.width < cropBoxFrame.height
    }
    
    fileprivate func setCroppingViews(hidden: Bool, animated: Bool) {
        if croppingViewsHidden == hidden {
            return
        }
        
        croppingViewsHidden = hidden
        
        
        let alpha: CGFloat = hidden ? 0 : 1
        
        if animated == false {
            gridOverlayView.alpha = alpha
//            toggleTranslucencyView(visible: !hidden)
        } else {
            UIView.animate(withDuration: 0.4) {
                self.gridOverlayView.alpha = alpha
//                self.toggleTranslucencyView(visible: !hidden)
            }
        }
    }
    
    
    fileprivate func setGridOverlay(hidden: Bool, animated: Bool) {
        gridOverlayHidden = hidden
        gridOverlayView.alpha = hidden ? 1.0 : 0
        
        UIView.animate(withDuration: 0.4) {
            self.gridOverlayView.alpha = hidden ? 0 : 1.0
        }
    }
}

extension CropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageViewContainer
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        canBeReset = true
        showDimmingBackground()
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        canBeReset = true
        showDimmingBackground()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        checkForCanReset()
        showVisualEffectBackground()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.isTracking {
            cropBoxLastEditedZoomScale = scrollView.zoomScale
            cropBoxLastEditedMinZoomScale = scrollView.minimumZoomScale
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        checkForCanReset()
        showVisualEffectBackground()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        showVisualEffectBackground()
        if decelerate == false {
//            startResetTimer()
        }
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
                imageView.addSubview(demoRotationCenterView!)
                
                let anchorPoint = CGPoint(x: rotationCenterOnImage.x * scrollView.zoomScale / imageView.frame.width, y: rotationCenterOnImage.y * scrollView.zoomScale / imageView.frame.height)

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
                set(editing: false, resetCropbox: true, animated: true)
            } else {
                currentPoint = nil
                previousPoint = nil
                rotationCal = nil
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
                    angleDashboard.rotateDailPlate(by: rotation)
                    imageView.transform = imageView.transform.rotated(by: rotation)
                }
                
                previousPoint = currentPoint
            }
        }
    }
}

extension CropView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == self.gridPanGestureRecognizer else { return true }
        
        let tapPoint = gestureRecognizer.location(in: self)
        
        let frame = gridOverlayView.frame
        let innerFrame = frame.insetBy(dx: 22, dy: 22)
        let outerFrame = frame.insetBy(dx: -22, dy: -22)
        
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
    private func startResetTimer() {
        set(editing: false, resetCropbox: true, animated: true)
    }
}

extension CropView {
    fileprivate func startEditing() {
        set(editing: true, resetCropbox: false, animated: true)
    }

    fileprivate func set(editing: Bool, resetCropbox: Bool, animated: Bool = false) {
        gridOverlayView.setGrid(hidden: !editing, animated: animated)
        
        if (resetCropbox) {
            moveCroppedContentToCenter(animated: animated)
            captureStateForImageRotation()
            cropBoxLastEditedAngle = angle
        }
    }
    
    func moveCroppedContentToCenter(animated: Bool = false) {
        
        var cropBoxFrame = self.cropBoxFrame
        let contentRect = contentBounds
        let scale = scrollView.zoomScale
        scrollView.contentSize = CGSize(width: contentBounds.width * scale, height: contentBounds.height * scale)
        
        func translate() {
            var rect = self.convert(self.cropBoxFrame, to: scrollView)
            rect = CGRect(x: rect.minX/scale, y: rect.minY/scale, width: rect.width/scale, height: rect.height/scale)
            scrollView.zoom(to: rect, animated: false)
            
            cropBoxFrame = GeometryTools.getIncribeRect(fromOutsideRect: contentRect, andInsideRect: cropBoxFrame)

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
    
    fileprivate func set(aspectRatio: CGSize, animated: Bool = false) {
        self.aspectRatio = aspectRatio
        
        // Will be executed automatically when added to a super view
        guard initialSetupPerformed == true else { return }
        
        // Passing in an empty size will revert back to the image aspect ratio
        if (aspectRatio.width < CGFloat.ulpOfOne && aspectRatio.height < CGFloat.ulpOfOne) {
            self.aspectRatio = imageSize()
        }
        
        var boundsFrame = contentBounds
        var cropBoxFrame = self.cropBoxFrame
        var offset = scrollView.contentOffset
        
        var cropBoxIsPortrait = false
        if Int(aspectRatio.width) == 1 && Int(aspectRatio.height) == 1 {
            cropBoxIsPortrait = image.size.width > self.image.size.height
        } else {
            cropBoxIsPortrait = aspectRatio.width < aspectRatio.height
        }
        
        var zoomOut = false
        if cropBoxIsPortrait {
            let newWidth = floor(cropBoxFrame.size.height * (aspectRatio.width/aspectRatio.height))
            var delta = cropBoxFrame.width - newWidth
            cropBoxFrame.size.width = newWidth;
            offset.x += (delta * 0.5)
            
            if (delta < CGFloat.ulpOfOne) {
                cropBoxFrame.origin.x = self.contentBounds.origin.x //set to 0 to avoid accidental clamping by the crop frame sanitizer
            }
            
            // If the aspect ratio causes the new width to extend
            // beyond the content width, we'll need to zoom the image out
            let boundsWidth = boundsFrame.width
            if (newWidth > boundsWidth) {
                var scale = boundsWidth / newWidth
                
                // Scale the new height
                let newHeight = cropBoxFrame.height * scale
                delta = cropBoxFrame.height - newHeight
                cropBoxFrame.size.height = newHeight
                
                // Offset the Y position so it stays in the middle
                offset.y += (delta * 0.5)
                
                // Clamp the width to the bounds width
                cropBoxFrame.size.width = boundsWidth
                zoomOut = true;
            }
        } else {
            let newHeight = floor(cropBoxFrame.width * (aspectRatio.height/aspectRatio.width))
            var delta = cropBoxFrame.height - newHeight
            cropBoxFrame.size.height = newHeight
            offset.y += (delta * 0.5)
            
            if (delta < CGFloat.ulpOfOne) {
                cropBoxFrame.origin.y = self.contentBounds.origin.y
            }
            
            // If the aspect ratio causes the new height to extend
            // beyond the content width, we'll need to zoom the image out
            let boundsHeight = boundsFrame.height
            if (newHeight > boundsHeight) {
                let scale = boundsHeight / newHeight
                
                // Scale the new width
                let newWidth = cropBoxFrame.size.width * scale
                delta = cropBoxFrame.size.width - newWidth
                cropBoxFrame.size.width = newWidth
                
                // Offset the Y position so it stays in the middle
                offset.x += (delta * 0.5)
                
                // Clamp the width to the bounds height
                cropBoxFrame.size.height = boundsHeight
                zoomOut = true;
            }
        }
        
        self.cropBoxLastEditedSize = cropBoxFrame.size
        self.cropBoxLastEditedAngle = angle
        
        func translate() {
            scrollView.contentOffset = offset;
            self.cropBoxFrame = cropBoxFrame;
            
            if (zoomOut) {
                scrollView.zoomScale = scrollView.minimumZoomScale;
            }
            
            moveCroppedContentToCenter(animated: false)
            checkForCanReset()
        }
        
        if animated == false {
            translate()
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.7, options: [.beginFromCurrentState], animations: {  translate() }, completion: nil)
        }
    }
    
    fileprivate func rotateImageNinetyDegrees(animated: Bool, clockwise: Bool = false) {
        //Only allow one rotation animation at a time
        if (rotateAnimationInProgress == true) {
            return
        }
        
        //Cancel any pending resizing timers
//        if (resetTimer != nil) {
//            set(editing: false, resetCropbox: true, animated: false)
//
//            cropBoxLastEditedAngle = angle
//            captureStateForImageRotation()
//        }
        
        //Work out the new angle, and wrap around once we exceed 360s
        var newAngle = self.angle
        newAngle = clockwise ? newAngle + 90 : newAngle - 90
        if (newAngle <= -360 || newAngle >= 360) {
            newAngle = 0
        }
        
        self.angle = newAngle
        
        //Convert the new angle to radians
        var angleInRadians = CGFloat(0)
        switch (newAngle) {
            case 90:    angleInRadians = CGFloat.pi / 2
            case -90:   angleInRadians = -CGFloat.pi / 2
            case 180:   angleInRadians = CGFloat.pi
            case -180:  angleInRadians = -CGFloat.pi / 2
            case 270:   angleInRadians = (CGFloat.pi + CGFloat.pi / 2)
            case -270:  angleInRadians = -(CGFloat.pi + CGFloat.pi / 2)
            default:
                print("default")
        }
        
        // Set up the transformation matrix for the rotation
        let rotation = CGAffineTransform.identity.rotated(by: angleInRadians)
        
        //Work out how much we'll need to scale everything to fit to the new rotation
        let contentBounds = self.contentBounds;
        var cropBoxFrame = self.cropBoxFrame;
        let scale = min(contentBounds.width / cropBoxFrame.height, contentBounds.height / cropBoxFrame.width)
        
        //Work out which section of the image we're currently focusing at
        let cropMidPoint = CGPoint(x: cropBoxFrame.midX, y: cropBoxFrame.midY)
        var cropTargetPoint = CGPoint(x: cropMidPoint.x + scrollView.contentOffset.x, y: cropMidPoint.y + scrollView.contentOffset.y)
        
        //Work out the dimensions of the crop box when rotated
        var newCropFrame = CGRect.zero
        if (labs(self.angle) == labs(cropBoxLastEditedAngle) || (labs(self.angle) * -1) == ((labs(self.cropBoxLastEditedAngle) - 180) % 360)) {
            newCropFrame.size = self.cropBoxLastEditedSize
            
            self.scrollView.minimumZoomScale = self.cropBoxLastEditedMinZoomScale
            self.scrollView.zoomScale = self.cropBoxLastEditedZoomScale
        }
        else {
            newCropFrame.size = CGSize(width: floor(cropBoxFrame.height * scale), height: cropBoxFrame.width * scale)
            
            //Re-adjust the scrolling dimensions of the scroll view to match the new size
            scrollView.minimumZoomScale *= scale
            scrollView.zoomScale *= scale
        }
        
        newCropFrame.origin.x = floor(contentBounds.midX - (newCropFrame.width * 0.5))
        newCropFrame.origin.y = floor(contentBounds.midY - (newCropFrame.height * 0.5))
        
        //If we're animated, generate a snapshot view that we'll animate in place of the real view
        var snapshotView: UIView?
        if (animated) {
//            snapshotView = foregroundContainerView.snapshotView(afterScreenUpdates: false)
            rotateAnimationInProgress = true
        }
        
        
        //Flip the content size of the scroll view to match the rotated bounds
        scrollView.contentSize = self.imageView.frame.size
        
        //assign the new crop box frame and re-adjust the content to fill it
        cropBoxFrame = newCropFrame
        moveCroppedContentToCenter(animated: false)
        newCropFrame = self.cropBoxFrame
        
        //work out how to line up out point of interest into the middle of the crop box
        cropTargetPoint.x *= scale
        cropTargetPoint.y *= scale
        
        //swap the target dimensions to match a 90 degree rotation (clockwise or counterclockwise)
        var swap = cropTargetPoint.x
        if (clockwise) {
            cropTargetPoint.x = self.scrollView.contentSize.width - cropTargetPoint.y
            cropTargetPoint.y = swap
        } else {
            cropTargetPoint.x = cropTargetPoint.y
            cropTargetPoint.y = self.scrollView.contentSize.height - swap
        }
        
        //reapply the translated scroll offset to the scroll view
        let midPoint = CGPoint(x: newCropFrame.midX, y: newCropFrame.midY)
        var offset = CGPoint.zero
        offset.x = floor(-midPoint.x + cropTargetPoint.x)
        offset.y = floor(-midPoint.y + cropTargetPoint.y)
        offset.x = max(-self.scrollView.contentInset.left, offset.x)
        offset.y = max(-self.scrollView.contentInset.top, offset.y)
        offset.x = min(self.scrollView.contentSize.width - (newCropFrame.size.width - self.scrollView.contentInset.right), offset.x)
        offset.y = min(self.scrollView.contentSize.height - (newCropFrame.size.height - self.scrollView.contentInset.bottom), offset.y)
        
        //if the scroll view's new scale is 1 and the new offset is equal to the old, will not trigger the delegate 'scrollViewDidScroll:'
        //so we should call the method manually to update the foregroundImageView's frame
        if (offset.x == self.scrollView.contentOffset.x && offset.y == self.scrollView.contentOffset.y && scale == 1) {
        }
        scrollView.contentOffset = offset
        
        //If we're animated, play an animation of the snapshot view rotating,
        //then fade it out over the live content
        if (animated) {
            guard let snapshotView = snapshotView else { return }
            
            snapshotView.center = CGPoint(x: contentBounds.midX, y: contentBounds.midY)
            addSubview(snapshotView)
            
            self.gridOverlayView.isHidden = true;
            
            func animation() {
                let angle = clockwise ? CGFloat.pi / 2 : -CGFloat.pi / 2
                snapshotView.transform = CGAffineTransform.identity.rotated(by: angle)
            }
            
            func completion() {
                gridOverlayView.isHidden = false;
                gridOverlayView.alpha = 0
                
                UIView.animate(withDuration: 0.45, animations: {
                    snapshotView.alpha = 0
                    self.gridOverlayView.alpha = 1.0
                }) { _ in
                    self.rotateAnimationInProgress = false
                    snapshotView.removeFromSuperview()
                    
                    // If the aspect ratio lock is not enabled, allow a swap
                    // If the aspect ratio lock is on, allow a aspect ratio swap
                    // only if the allowDimensionSwap option is specified.
                    let aspectRatioCanSwapDimensions = !self.aspectRatioLockEnabled ||
                        (self.aspectRatioLockEnabled && self.aspectRatioLockDimensionSwapEnabled)
                    
                    if (!aspectRatioCanSwapDimensions) {
                        //This will animate the aspect ratio back to the desired locked ratio after the image is rotated.
                        self.set(aspectRatio: self.aspectRatio, animated: animated)
                    }

                }
            }
            
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.8, options: .beginFromCurrentState, animations: {
                animation()
            }, completion: { _ in
                completion()
            })
        }
            
        checkForCanReset()
    }
    
    fileprivate func captureStateForImageRotation() {
        cropBoxLastEditedSize = cropBoxFrame.size
        cropBoxLastEditedZoomScale = scrollView.zoomScale
        cropBoxLastEditedMinZoomScale = scrollView.minimumZoomScale
    }
    
    fileprivate func checkForCanReset() {
        var canReset = false
        if (angle != 0) { //Image has been rotated
            canReset = true
        } else if (scrollView.zoomScale > scrollView.minimumZoomScale + CGFloat.ulpOfOne) { //image has been zoomed in
            canReset = true
        } else if (Int(floor(cropBoxFrame.width)) != Int(floor(originalCropBoxSize.width)))
            || (Int(floor(cropBoxFrame.height)) != Int(floor(originalCropBoxSize.height))) {
            //crop box has been changed
            canReset = true
        } else if (Int(floor(scrollView.contentOffset.x)) != Int(floor(originalContentOffset.x)))
            || (Int(floor(scrollView.contentOffset.y)) != Int(floor(originalContentOffset.y))) {
            //crop box has been changed
            canReset = true
        }
        
        self.canBeReset = canReset
    }
    
    fileprivate func imageSize() -> CGSize {
        if [-90, -270, 90, 270].contains(angle) {
            return CGSize(width: image.size.height, height: image.size.width)
        }
        
        return image.size
    }
    
    fileprivate func hasAspectRatio() -> Bool {
        return aspectRatio.width > CGFloat.ulpOfOne && aspectRatio.height > CGFloat.ulpOfOne
    }
}
