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
            set(simpleRenderMode: simpleRenderMode, animated: false)
        }
    }
    
    fileprivate var panOriginPoint = CGPoint.zero
    
    fileprivate var contentBounds: CGRect {
        var contentRect = CGRect.zero
        contentRect.origin.x = cropViewPadding
        contentRect.origin.y = cropViewPadding
        contentRect.size.width = bounds.width - 2 * cropViewPadding
        contentRect.size.height = bounds.height - 2 * cropViewPadding
    
        return contentRect
    }
    
    fileprivate var cropBoxFrame = CGRect.zero {
        didSet {
            if oldValue.equalTo(cropBoxFrame) { return }

            //clamp the cropping region to the inset boundaries of the screen
            let contentFrame = contentBounds
            let xOrigin = ceil(contentFrame.origin.x)
            let xDelta = cropBoxFrame.origin.x - xOrigin
            cropBoxFrame.origin.x = floor(max(cropBoxFrame.origin.x, xOrigin))
            
            //If we clamp the x value, ensure we compensate for the subsequent delta generated in the width (Or else, the box will keep growing)
            if xDelta < CGFloat.ulpOfOne {
                cropBoxFrame.size.width += xDelta
            }
            
            let yOrigin = ceil(contentFrame.origin.y)
            let yDelta = cropBoxFrame.origin.y - yOrigin
            cropBoxFrame.origin.y = floor(max(cropBoxFrame.origin.y, yOrigin))

            if yDelta < CGFloat.ulpOfOne {
                cropBoxFrame.size.height += yDelta
            }
            
            //given the clamped X/Y values, make sure we can't extend the crop box beyond the edge of the screen in the current state
            let maxWidth = (contentFrame.size.width + contentFrame.origin.x) - cropBoxFrame.origin.x
            cropBoxFrame.size.width = floor(min(cropBoxFrame.size.width, maxWidth))

            let maxHeight = (contentFrame.size.height + contentFrame.origin.y) - cropBoxFrame.origin.y
            cropBoxFrame.size.height = floor(min(cropBoxFrame.size.height, maxHeight))
            
            //Make sure we can't make the crop box too small
            cropBoxFrame.size.width  = max(cropBoxFrame.size.width, cropViewMinimumBoxSize)
            cropBoxFrame.size.height = max(cropBoxFrame.size.height, cropViewMinimumBoxSize)
            
            gridOverlayView.frame = cropBoxFrame
            dimmingView.adaptMaskTo(match: cropBoxFrame)
            visualEffectView.adaptMaskTo(match: cropBoxFrame)
            
            /*
            //reset the scroll view insets to match the region of the new crop rect
            scrollView.contentInset = UIEdgeInsets(top: cropBoxFrame.minY, left: cropBoxFrame.minX, bottom: bounds.maxY - cropBoxFrame.maxY, right: bounds.minX - cropBoxFrame.maxX)
            
            //if necessary, work out the new minimum size of the scroll view so it fills the crop box
            let imageSize = imageView.bounds.size
            let scale = max(cropBoxFrame.size.height/imageSize.height, cropBoxFrame.size.width/imageSize.width)
            scrollView.minimumZoomScale = scale
            
            //make sure content isn't smaller than the crop box
            var size = self.scrollView.contentSize
            size.width = floor(size.width)
            size.height = floor(size.height)
            scrollView.contentSize = size

//            //IMPORTANT: Force the scroll view to update its content after changing the zoom scale
            scrollView.zoomScale = scrollView.zoomScale */
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
    
    fileprivate var applyInitialCroppedImageFrame = false
    fileprivate var internalLayoutDisabled = false
    
    fileprivate var cropAdjustingDelay = 0.8
    fileprivate var cropViewPadding = CGFloat(14.0)
    fileprivate var maximumZoomScale = 15.0
    
    fileprivate var aspectRatio = CGSize(width: 4.0, height: 3.0)
    
    fileprivate var image: UIImage!
    fileprivate var scrollView: CropScrollView!
    
    fileprivate var aspectRatioLockEnabled = false
    
    fileprivate var gridOverlayView: CropOverlayView!
    fileprivate var gridPanGestureRecognizer: UIPanGestureRecognizer!
    fileprivate var resetTimer: Timer?
    
    private lazy var initialCropBoxRect: CGRect = {
        guard let image = image else { return .zero }
        guard image.size.width > 0 && image.size.height > 0 else { return .zero }
        
        let frame = CGRect(x: cropViewPadding, y: cropViewPadding, width: self.bounds.width - cropViewPadding * 2, height: self.bounds.height - cropViewPadding * 2)
        
        let imageRatio = image.size.width / image.size.height
        let viewRatio = frame.width / frame.height
        
        var rect = CGRect(origin: .zero, size: image.size)
        if viewRatio > imageRatio {
            rect.size.width *= frame.height / rect.height
            rect.size.height = frame.height
        } else {
            rect.size.height *= frame.width / rect.width
            rect.size.width = frame.width
        }
        
        rect.origin.x = frame.midX - rect.width / 2
        rect.origin.y = frame.midY - rect.height / 2
        
        return rect
    } ()
    
    fileprivate var imageView: UIImageView!
    fileprivate var dimmingView: CropDimmingView!
    fileprivate var visualEffectView: CropVisualEffectView!
    fileprivate var angleDashboard: AngleDashboard!
    
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
        
        setup()
        adaptForCropBox()
    }
    
    private func setup() {
        backgroundColor =  UIColor(white: 0.12, alpha: 1)
        
        setupScrollView()

        imageView = createImageView(image: image)
        scrollView.addSubview(imageView)
        
        setupTranslucencyView()
        setupOverlayView()
        setGridOverlayView()

        // The pan controller to recognize gestures meant to resize the grid view
        gridPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(gridPanGestureRecognized))
        gridPanGestureRecognizer.delegate = self
        scrollView.panGestureRecognizer.require(toFail: gridPanGestureRecognizer)
        addGestureRecognizer(gridPanGestureRecognizer)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }
    
    @objc func handleDoubleTap(recognizer: UIPanGestureRecognizer) {
        reset()
    }
    
    func adaptForCropBox() {
        cropBoxFrame = initialCropBoxRect
        cropOrignFrame = cropBoxFrame
        scrollView.frame = CGRect(origin: .zero, size: bounds.size)
        imageView.frame = initialCropBoxRect
        
        setupAngleDashboard()
    }
    
    private func setupScrollView() {
        scrollView = CropScrollView(frame: bounds)
        scrollView.touchesBegan = { [weak self] in
            self?.startEditing()
            self?.showDimmingBackground()
        }
        scrollView.touchesEnded = { [weak self] in
            self?.startResetTimer()
            self?.showVisualEffectBackground()
        }
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 15.0
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
        addSubview(dimmingView)
        dimmingView.alpha = 0
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
        
        let boardLength = min(bounds.width, bounds.height) * 0.8
        let x = (bounds.width - boardLength) / 2
        let y = gridOverlayView.frame.maxY
        angleDashboard = AngleDashboard(frame: CGRect(x: x, y: y, width: boardLength, height: 50))
        addSubview(angleDashboard)
    }
    
    private func adaptAngleDashboardToCropBox() {
        angleDashboard.frame.origin.y = gridOverlayView.frame.maxY
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
        
        if (!restoreImageCropFrame.isEmpty) {
            imageCropFrame = restoreImageCropFrame
            restoreImageCropFrame = .zero
        }
        
        captureStateForImageRotation()
        checkForCanReset()
    }()
    
    fileprivate func layoutInitialImage() {
        let imageSize = self.imageSize()
        scrollView.contentSize = imageSize
        
        let bounds = contentBounds
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
        if (frame.size.width < scaledSize.width - CGFloat.ulpOfOne || frame.size.height < scaledSize.height - CGFloat.ulpOfOne) {
            var offset = CGPoint.zero
            offset.x = -floor(bounds.midX - (scaledSize.width * 0.5))
            offset.y = -floor(bounds.midY - (scaledSize.height * 0.5))
            scrollView.contentOffset = offset
        }
        
        //save the current state for use with 90-degree rotations
        cropBoxLastEditedAngle = 0
        captureStateForImageRotation()
        
        //save the size for checking if we're in a resettable state
        originalCropBoxSize = scaledImageSize
        originalContentOffset = scrollView.contentOffset
        
        checkForCanReset()
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
        
        let imageRefFrame = CGRect(x: imageView.frame.origin.x - 1, y: imageView.frame.origin.y - 1, width: imageView.frame.width + 2, height: imageView.frame.height + 2 )
        if imageRefFrame.contains(newCropBoxFrame) {
            cropBoxFrame = newCropBoxFrame
        }
        
//        let cropBoxClamper = CropBoxClamper(contentFrame: contentFrame, cropOriginFrame: cropOrignFrame, cropBoxFrame: cropBoxFrame)
//        cropBoxFrame = cropBoxClamper.clamp(cropBoxFrame: cropBoxFrame, withOriginalFrame: cropOrignFrame, andUpdateCropBoxFrameInfo: info)
//        checkForCanReset()
    }
    
    fileprivate func resetLayoutToDefault(animated: Bool = false) {
        // If resetting the crop view includes resetting the aspect ratio,
        // reset it to zero here. But set the ivar directly since there's no point
        // in performing the relayout calculations right before a reset.
        if hasAspectRatio() {
            aspectRatio = CGSize.zero
        }
        
        if animated == false && angle != 0 {
            //Reset all of the rotation transforms
            angle = 0
            
            //Set the scroll to 1.0f to reset the transform scale
            scrollView.zoomScale = 1.0
            
//            let imageRect = CGRect(origin: CGPoint.zero, size: image.size)
            
            layoutInitialImage()
            checkForCanReset()
            return
        }
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
        return imageView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startEditing()
        canBeReset = true
        showDimmingBackground()
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        startEditing()
        canBeReset = true
        showDimmingBackground()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        startResetTimer()
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
        startResetTimer()
        checkForCanReset()
        showVisualEffectBackground()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        showVisualEffectBackground()
        if decelerate == false {
            startResetTimer()
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

extension CropView {
    @objc func gridPanGestureRecognized(recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self)
        
        if recognizer.state == .began {
            if isAngleDashboardTouched(forPoint: point) {
                forCrop = false
                rotationCal = RotationCalculator(midPoint: point)
                currentPoint = point
                previousPoint = point
            } else {
                startEditing()
                panOriginPoint = point
                cropOrignFrame = cropBoxFrame
                tappedEdge = cropEdge(forPoint: point)
                showDimmingBackground()
            }
        }
        
        if recognizer.state == .ended {
            if forCrop {
                startResetTimer()
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
                let rotation = rotationCal?.getRotation(byOldPoint: previousPoint!, andNewPoint: currentPoint!)
                print("rotation is \(rotation!)")
                
                angleDashboard.rotateDailPlate(by: rotation ?? 0)
                imageView.transform = imageView.transform.rotated(by: rotation ?? 0)
                
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

// Timer
extension CropView {
    private func startResetTimer() {
        guard resetTimer == nil else {
            return
        }
        
        resetTimer = Timer.scheduledTimer(timeInterval: cropAdjustingDelay, target: self, selector: #selector(timerTriggered), userInfo: nil, repeats: false)
    }

    @objc private func timerTriggered() {
        set(editing: false, resetCropbox: true, animated: true)
        cancelResetTimer()
    }
    
    private func cancelResetTimer() {
        resetTimer?.invalidate()
        resetTimer = nil
    }
}

extension CropView {
    fileprivate func startEditing() {
        cancelResetTimer()
        set(editing: true, resetCropbox: false, animated: true)
    }

    fileprivate func set(editing: Bool, resetCropbox: Bool, animated: Bool = false) {
//        if editing == self.editing { return }
//
//        self.editing = editing
        
        gridOverlayView.setGrid(hidden: !editing, animated: animated)
        
        if (resetCropbox) {
            moveCroppedContentToCenter(animated: animated)
            captureStateForImageRotation()
            cropBoxLastEditedAngle = angle
        }
    }
    
    func moveCroppedContentToCenter(animated: Bool = false) {
        if internalLayoutDisabled { return }

        var cropBoxFrame = self.cropBoxFrame
        
        // Ensure we only proceed after the crop frame has been setup for the first time
        if cropBoxFrame.width < CGFloat.ulpOfOne || cropBoxFrame.height < CGFloat.ulpOfOne {
            return
        }
        
        let contentRect = contentBounds

        //The scale we need to scale up the crop box to fit full screen
        let scale = min(contentRect.width / cropBoxFrame.width, contentRect.height / cropBoxFrame.height)
        
        let focusPoint = CGPoint(x: cropBoxFrame.midX, y: cropBoxFrame.midY)
        let midPoint = CGPoint(x: contentRect.midX, y: contentRect.midY)
        
        cropBoxFrame.size.width = ceil(cropBoxFrame.width * scale)
        cropBoxFrame.size.height = ceil(cropBoxFrame.height * scale)
        cropBoxFrame.origin.x = contentRect.origin.x + ceil(0.5 * (contentRect.width - cropBoxFrame.width))
        cropBoxFrame.origin.y = contentRect.origin.y + ceil(0.5 * (contentRect.height - cropBoxFrame.height))
        
        //Work out the point on the scroll content that the focusPoint is aiming at
        var contentTargetPoint = CGPoint()
        contentTargetPoint.x = ((focusPoint.x + scrollView.contentOffset.x) * scale)
        contentTargetPoint.y = ((focusPoint.y + scrollView.contentOffset.y) * scale)

        //Work out where the crop box is focusing, so we can re-align to center that point
        var offset = CGPoint()
        offset.x = -midPoint.x + contentTargetPoint.x
        offset.y = -midPoint.y + contentTargetPoint.y

        //clamp the content so it doesn't create any seams around the grid
        offset.x = max(-cropBoxFrame.origin.x, offset.x)
        offset.y = max(-cropBoxFrame.origin.y, offset.y)
        
        func translate() {
            if (scale < CGFloat(1.0) - CGFloat.ulpOfOne || scale > CGFloat(1.0) + CGFloat.ulpOfOne) {
                scrollView.zoomScale *= scale
                scrollView.zoomScale = min(scrollView.maximumZoomScale, scrollView.zoomScale)
            }
            
            // If it turns out the zoom operation would have exceeded the minizum zoom scale, don't apply
            // the content offset
            if (scrollView.zoomScale < scrollView.maximumZoomScale - CGFloat.ulpOfOne) {
                offset.x = min(-cropBoxFrame.maxX + scrollView.contentSize.width, offset.x)
                offset.y = min(-cropBoxFrame.maxY + scrollView.contentSize.height, offset.y)
                scrollView.contentOffset = offset
            }
            
            self.cropBoxFrame = cropBoxFrame
            
            adaptAngleDashboardToCropBox()
        }
        
        if animated == false {
            translate()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .beginFromCurrentState, animations: {translate()}, completion: { [weak self] _ in
                    self?.angleDashboard.isHidden = false
                })
            }
        }
    }
    
    fileprivate func set(simpleRenderMode: Bool, animated: Bool = false) {
        if simpleRenderMode == self.simpleRenderMode { return }
        
        self.simpleRenderMode = simpleRenderMode
        editing = false
        
        if animated == false {
//            toggleTranslucencyView(visible: !simpleRenderMode)
        } else {
            UIView.animate(withDuration: 0.25) {
//                self.toggleTranslucencyView(visible: !simpleRenderMode)
            }
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
        if (resetTimer != nil) {
            cancelResetTimer()
            set(editing: false, resetCropbox: true, animated: false)
            
            cropBoxLastEditedAngle = angle
            captureStateForImageRotation()
        }
        
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
