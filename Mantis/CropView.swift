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
    let cropViewMinimumBoxSize = CGFloat(42)
    var minimumAspectRatio = CGFloat(0)
    
    var simpleRenderMode = true {
        didSet {
            
        }
    }
    
    fileprivate var panOriginPoint = CGPoint.zero
    
    fileprivate var cropBoxFrame = CGRect.zero {
        didSet {
            // to do
        }
    }
    
    fileprivate var editing = false {
        didSet {
            // to do
        }
    }
    
    fileprivate var imageCropFrame: CGRect {
        get {
            return CGRect.zero
        }
        
        set {
            
        }
    }
    
    var imageViewFrame: CGRect {
        get {
            return CGRect.zero
        }
    }
    
    var canBeReset: Bool = true {
        didSet {
            
        }
    }
    
    fileprivate var cropOrignFrame = CGRect.zero
    fileprivate var tappedEdge = CropViewOverlayEdge.none
    
    fileprivate var angle = 0 {
        didSet {
            
        }
    }
    
    fileprivate var originalCropBoxSize = CGSize.zero
    fileprivate var originalContentOffset = CGPoint.zero
    
    fileprivate var rotationContentOffset = CGPoint.zero
    fileprivate var rotationContentSize = CGSize.zero
    fileprivate var rotationBoundFrame = CGRect.zero
    
    fileprivate var restoreAngle = 0
    fileprivate var cropBoxLastEditedAngle = 0
    
    fileprivate var restoreImageCropFrame = CGRect.zero
    
    fileprivate var applyInitialCroppedImageFrame = false
    
    fileprivate var cropAdjustingDelay = 0.8
    fileprivate var cropViewPadding = CGFloat(14.0)
    fileprivate var maximumZoomScale = 15.0
    
    fileprivate var aspectRatio = CGSize(width: 4.0, height: 3.0)
    
    fileprivate var image: UIImage!
    fileprivate var scrollView: CropScrollView!
    
    fileprivate var backgroundImageView: UIImageView!
    fileprivate var backgroundContainerView: UIView!
    fileprivate var foregroundImageView: UIImageView!
    fileprivate var foregroundContainerView: UIView!
    
    /* At times during animation, disable matching the forground image view to the background */
    fileprivate var disableForgroundMatching = false
    
    fileprivate var aspectRatioLockEnabled = false
    
    fileprivate var overlayView: UIView!
    fileprivate var gridOverlayView: CropOverlayView!
    
    fileprivate var gridPanGestureRecognizer: UIPanGestureRecognizer!
    
    fileprivate var resetTimer: Timer?
    
    // Fix-Me
    init(image: UIImage) {
        super.init(frame: CGRect.zero)
        self.image = image
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setup() {
        backgroundColor = UIColor(white: 0.12, alpha: 1)
        
        setupScrollView()
        setupBackgroundContainer(parentView: scrollView)
        setupOverlayView()
        setupForegroundContainer(parentView: self)
        setGridOverlayView()
    }
    
    private func setupScrollView() {
        scrollView = CropScrollView(frame: bounds)
        scrollView.touchesBegan = { [weak self] in self?.startEditing() }
        scrollView.touchesEnded = { [weak self] in self?.startResetTimer() }
    }
    
    private func createImageView(image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.layer.minificationFilter = .trilinear
        imageView.accessibilityIgnoresInvertColors = true
        return imageView
    }
    
    private func setupBackgroundContainer(parentView: UIView) {
        backgroundImageView = createImageView(image: image)
        backgroundContainerView = UIView(frame: backgroundImageView.bounds)
        backgroundContainerView.addSubview(backgroundImageView)
        parentView.addSubview(backgroundContainerView)
    }
    
    private func setupOverlayView() {
        overlayView = UIView(frame: bounds)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.backgroundColor = backgroundColor?.withAlphaComponent(0.35)
        overlayView.isUserInteractionEnabled = false
        addSubview(overlayView)
    }
    
    private func setupForegroundContainer(parentView: UIView) {
        foregroundImageView = createImageView(image: image)
        foregroundContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        foregroundContainerView.clipsToBounds = true
        foregroundContainerView.isUserInteractionEnabled = false
        foregroundContainerView.addSubview(foregroundImageView)
        parentView.addSubview(foregroundContainerView)
    }
    
    private func setGridOverlayView() {
        gridOverlayView = CropOverlayView(frame: foregroundContainerView.frame)
        gridOverlayView.isUserInteractionEnabled = false
        gridOverlayView.gridHidden = true
        addSubview(gridOverlayView)
    }
    
    func performInitialSetup() {
        _ = initialSetup
    }
    // Make sure that it is execued only once
    lazy var initialSetup: Void = {
        layoutInitialImage()
        
        // -- State Restoration --
        
        if (restoreAngle != 0) {
            angle = restoreAngle
            cropBoxLastEditedAngle = angle
            restoreAngle = 0
        }
        
        if (restoreImageCropFrame.isEmpty) {
            imageCropFrame = restoreImageCropFrame
            restoreImageCropFrame = .zero
        }
        
        captureStateForImageRotation()
        checkForCanReset()
    }()
    
    fileprivate func layoutInitialImage() {
        let imageSize = self.imageSize()
        scrollView.contentSize = imageSize
        
        let bounds = self.contentBounds()
        let boundsSize = bounds.size
        
        //work out the minimum scale of the object
        var scale = CGFloat(0)
        
        // Work out the size of the image to fit into the content bounds
        scale = min(boundsSize.width/imageSize.width, boundsSize.height/imageSize.height)
        let scaledImageSize = CGSize(width: floor(imageSize.width * scale), height: floor(imageSize.height * scale))
        
        // If an aspect ratio was pre-applied to the crop view, use that to work out the minimum scale the image needs to be to fit
        if hasAspectRatio() {
            let ratioScale = aspectRatio.width / aspectRatio.height
            let fullSizeRatio = CGSize(width: boundsSize.width * ratioScale, height: boundsSize.height)
            let fitScale = min(boundsSize.width/fullSizeRatio.width, boundsSize.height/fullSizeRatio.height)
            let cropBoxSize = CGSize(width: fullSizeRatio.width * fitScale, height: fullSizeRatio.height * fitScale)
            scale = max(cropBoxSize.width/imageSize.width, cropBoxSize.height/imageSize.height)
        }
        
        //Whether aspect ratio, or original, the final image size we'll base the rest of the calculations off
        let scaledSize = CGSize(width: floor(imageSize.width * scale), height: floor(imageSize.height * scale))
        
        //set the fully zoomed out state initially
        scrollView.zoomScale = self.scrollView.minimumZoomScale
        scrollView.contentSize = scaledSize
        
        // If we ended up with a smaller crop box than the content, line up the content so its center
        // is in the center of the cropbox
        if (frame.size.width < scaledSize.width - CGFloat(Float.ulpOfOne) || frame.size.height < scaledSize.height - CGFloat(Float.ulpOfOne)) {
            var offset = CGPoint.zero
            offset.x = -floor(bounds.midX - (scaledSize.width * 0.5))
            offset.y = -floor(bounds.midY - (scaledSize.height * 0.5))
            scrollView.contentOffset = offset;
        }
        
        //save the current state for use with 90-degree rotations
        cropBoxLastEditedAngle = 0
        captureStateForImageRotation()
        
        //save the size for checking if we're in a resettable state
        originalCropBoxSize = scaledImageSize
        originalContentOffset = scrollView.contentOffset
        
        checkForCanReset()
        matchForegroundToBackground()
    }
    
    fileprivate func prepareforRotation() {
        rotationContentOffset = scrollView.contentOffset
        rotationContentSize = scrollView.contentSize
        rotationBoundFrame = contentBounds()
    }
    
    fileprivate func performRelayoutForRotation() {
        
    }
    
    fileprivate func matchForegroundToBackground() {
        guard disableForgroundMatching == false else {
            return
        }
        
        //We can't simply match the frames since if the images are rotated, the frame property becomes unusable
        guard let superview = backgroundContainerView.superview else {
            return
        }
        
        foregroundImageView.frame = superview.convert(backgroundContainerView.frame, to: foregroundContainerView)
    }
    
    fileprivate func updateCropBoxFrame(withGesturePoint point: CGPoint) {
        let contentFrame = contentBounds()
        
        var point = point
        point.x = max(contentFrame.origin.x - cropViewPadding, point.x);
        point.y = max(contentFrame.origin.y - cropViewPadding, point.y);
        
        //The delta between where we first tapped, and where our finger is now
        let xDelta = ceil(point.x - panOriginPoint.x)
        let yDelta = ceil(point.y - panOriginPoint.y)
        
        var info = UpdateCropBoxFrameInfo(false, false, false, false)
        
        if aspectRatioLockEnabled {
            var cropBoxLockedAspectFrameUpdater = CropBoxLockedAspectFrameUpdater(tappedEdge: tappedEdge, contentFrame: contentFrame, cropOriginFrame: cropOrignFrame, cropBoxFrame: cropBoxFrame)
            let aspectInfo = cropBoxLockedAspectFrameUpdater.updateCropBoxFrame(xDelta: xDelta, yDelta: yDelta)
            info.aspectHorizontal = aspectInfo.aspectHorizontal
            info.aspectVertical = aspectInfo.aspectVertical
            
            cropBoxFrame = cropBoxLockedAspectFrameUpdater.cropBoxFrame
        } else {
            var cropBoxFreeAspectFrameUpdater = CropBoxFreeAspectFrameUpdater(tappedEdge: tappedEdge, contentFrame: contentFrame, cropOriginFrame: cropOrignFrame, cropBoxFrame: cropBoxFrame)
            let clampInfo = cropBoxFreeAspectFrameUpdater.updateCropBoxFrame(xDelta: xDelta, yDelta: yDelta)
            info.clampMinFromLeft = clampInfo.clampMinFromLeft
            info.clampMinFromTop = clampInfo.clampMinFromTop
            
            cropBoxFrame = cropBoxFreeAspectFrameUpdater.cropBoxFrame
        }
        
        let cropBoxClamper = CropBoxClamper(contentFrame: contentFrame, cropOriginFrame: cropOrignFrame, cropBoxFrame: cropBoxFrame)
        cropBoxFrame = cropBoxClamper.clamp(cropBoxFrame: cropBoxFrame, withOriginalFrame: cropOrignFrame, andUpdateCropBoxFrameInfo: info)
        checkForCanReset()
    }
    
    fileprivate func resetLayoutToDefault(animated: Bool = false) {
        
    }
    
    fileprivate func toggleTranslucencyView(visible: Bool) {
        
    }
    
    fileprivate func update(toImageCropFrame: CGRect) {
        
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
        
        let leftRect = CGRect(origin: touchRect.origin, size: CGSize(width: touchRect.width, height: touchUnit))
        if leftRect.contains(point) { return .top }
        
        return .none
    }
    
    fileprivate func setCropBox(resizeEnabled: Bool) {
        
    }
    
    fileprivate func cropBoxAspectRatioIsPortrait() -> Bool {
        return true
    }
    
    fileprivate func setCroppingViews(hidden: Bool, animated: Bool) {
        
    }
    
    fileprivate func setBackgroundImageView(hidden: Bool, animated: Bool) {
        
    }
    
    fileprivate func setGridOverlay(hidden: Bool, animated: Bool) {
        
    }
}

extension CropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
}

extension CropView {
    func gridPanGestureRecognized(recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self)
        
        if recognizer.state == .began {
            startEditing()
            cropOrignFrame = cropBoxFrame
            tappedEdge = cropEdge(forPoint: point)
        }
        
        if recognizer.state == .ended {
            startResetTimer()
        }
        
        
    }
}

extension CropView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if gridPanGestureRecognizer.state == .changed {
            return false
        }
        
        return true
    }
}

// Timer
extension CropView {
    private func startResetTimer() {
        
    }

    private func timerTriggered() {
        
    }
    
    private func cancelResetTimer() {
        
    }
}

extension CropView {
    fileprivate func startEditing() {
        
    }

    fileprivate func set(editing: Bool, resetCropbox: Bool, animated: Bool = false) {
        
    }
    
    fileprivate func moveCroppedContentToCenter(animated: Bool = false) {
        
    }
    
    fileprivate func set(simpleRenderMode: Bool, animated: Bool = false) {
        
    }
    
    fileprivate func set(aspectRatio: CGSize, animated: Bool = false) {
        
    }
    
    fileprivate func rotateImageNinetyDegrees(animated: Bool, clockwise: Bool = false) {
        
    }
    
    fileprivate func captureStateForImageRotation() {
        
    }
    
    fileprivate func checkForCanReset() {
    
    }
    
    fileprivate func contentBounds() -> CGRect {
        var contentRect = CGRect.zero
        contentRect.origin.x = cropViewPadding
        contentRect.origin.y = cropViewPadding
        contentRect.size.width = bounds.width - 2 * cropViewPadding
        contentRect.size.height = bounds.height - 2 * cropViewPadding
        
        return contentRect
    }
    
    fileprivate func imageSize() -> CGSize {
        if [-90, -270, 90, 270].contains(angle) {
            return CGSize(width: image.size.height, height: image.size.width)
        }
        
        return image.size
    }
    
    fileprivate func hasAspectRatio() -> Bool {
        return Float(aspectRatio.width) > Float.ulpOfOne && Float(aspectRatio.height) > Float.ulpOfOne
    }
    
}
