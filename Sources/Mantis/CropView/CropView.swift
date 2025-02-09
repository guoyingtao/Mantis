//
//  CropView.swift
//  Mantis
//
//  Created by Echo on 10/20/18.
//  Copyright © 2018 Echo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

protocol CropViewDelegate: AnyObject {
    func cropViewDidBecomeResettable(_ cropView: CropViewProtocol)
    func cropViewDidBecomeUnResettable(_ cropView: CropViewProtocol)
    func cropViewDidBeginResize(_ cropView: CropViewProtocol)
    func cropViewDidEndResize(_ cropView: CropViewProtocol)
    func cropViewDidBeginCrop(_ cropView: CropViewProtocol)
}

final class CropView: UIView {
    var image: UIImage
    
    let viewModel: CropViewModelProtocol
    
    weak var delegate: CropViewDelegate? {
        didSet {
            checkImageStatusChanged()
        }
    }
    
    var aspectRatioLockEnabled = false
    
    // Referred to in extension
    let imageContainer: ImageContainerProtocol
    let cropAuxiliaryIndicatorView: CropAuxiliaryIndicatorViewProtocol
    let cropWorkbenchView: CropWorkbenchViewProtocol
    let cropMaskViewManager: CropMaskViewManagerProtocol
    
    var rotationControlView: RotationControlViewProtocol? {
        didSet {
            if rotationControlView?.isAttachedToCropView == true {
                addSubview(rotationControlView!)
            }
        }
    }
    
    var isManuallyZoomed = false
    var forceFixedRatio = false
    var checkForForceFixedRatioFlag = false
    let cropViewConfig: CropViewConfig
    
    private var flipOddTimes = false
    
    lazy private var activityIndicator: ActivityIndicatorProtocol = {
        let activityIndicator: ActivityIndicatorProtocol
        if let indicator = cropViewConfig.cropActivityIndicator {
            activityIndicator = indicator
        } else {
            let indicator = UIActivityIndicatorView(frame: .zero)
            indicator.color = .white
            indicator.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
            activityIndicator = indicator
        }
        
        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: cropViewConfig.cropActivityIndicatorSize.width).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: cropViewConfig.cropActivityIndicatorSize.width).isActive = true
        
        return activityIndicator
    }()
    
    deinit {
        print("CropView deinit.")
    }
    
    init(
        image: UIImage,
        cropViewConfig: CropViewConfig,
        viewModel: CropViewModelProtocol,
        cropAuxiliaryIndicatorView: CropAuxiliaryIndicatorViewProtocol,
        imageContainer: ImageContainerProtocol,
        cropWorkbenchView: CropWorkbenchViewProtocol,
        cropMaskViewManager: CropMaskViewManagerProtocol
    ) {
        self.image = image
        self.cropViewConfig = cropViewConfig
        self.viewModel = viewModel
        self.cropAuxiliaryIndicatorView = cropAuxiliaryIndicatorView
        self.imageContainer = imageContainer
        self.cropWorkbenchView = cropWorkbenchView
        self.cropMaskViewManager = cropMaskViewManager
        
        super.init(frame: .zero)
        
        if let color = cropViewConfig.backgroundColor {
            self.backgroundColor = color
        }
        
        viewModel.statusChanged = { [weak self] status in
            self?.render(by: status)
        }
        
        viewModel.cropBoxFrameChanged = { [weak self] cropBoxFrame in
            self?.handleCropBoxFrameChange(cropBoxFrame)
        }
        
        viewModel.setInitialStatus()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func handleCropBoxFrameChange(_ cropBoxFrame: CGRect) {
        cropAuxiliaryIndicatorView.frame = cropBoxFrame
        
        var cropRatio: CGFloat = 1.0
        if cropAuxiliaryIndicatorView.frame.height != 0 {
            cropRatio = self.cropAuxiliaryIndicatorView.frame.width / self.cropAuxiliaryIndicatorView.frame.height
        }
        
        cropMaskViewManager.adaptMaskTo(match: cropBoxFrame, cropRatio: cropRatio)
    }
    
    private func initialRender() {
        setupCropWorkbenchView()
        setupCropAuxiliaryIndicatorView()
        checkImageStatusChanged()
    }
    
    private func render(by viewStatus: CropViewStatus) {
        cropAuxiliaryIndicatorView.isHidden = false
        
        switch viewStatus {
        case .initial:
            initialRender()
        case .rotating:
            rotateCropWorkbenchView()
        case .degree90Rotating:
            cropMaskViewManager.showVisualEffectBackground(animated: true)
            cropAuxiliaryIndicatorView.isHidden = true
            toggleRotationControlViewIsNeeded(isHidden: true)
        case .touchImage:
            cropMaskViewManager.showDimmingBackground(animated: true)
            cropAuxiliaryIndicatorView.gridLineNumberType = .crop
            cropAuxiliaryIndicatorView.gridHidden = false
        case .touchCropboxHandle(let tappedEdge):
            cropAuxiliaryIndicatorView.handleIndicatorHandleTouched(with: tappedEdge)
            toggleRotationControlViewIsNeeded(isHidden: true)
            cropMaskViewManager.showDimmingBackground(animated: true)
        case .touchRotationBoard:
            cropAuxiliaryIndicatorView.gridLineNumberType = .rotate
            cropAuxiliaryIndicatorView.gridHidden = false
            cropMaskViewManager.showDimmingBackground(animated: true)
        case .betweenOperation:
            cropAuxiliaryIndicatorView.handleEdgeUntouched()
            toggleRotationControlViewIsNeeded(isHidden: false)
            adaptRotationControlViewToCropBoxIfNeeded()
            cropMaskViewManager.showVisualEffectBackground(animated: true)
            checkImageStatusChanged()
        }
    }
    
    private func toggleRotationControlViewIsNeeded(isHidden: Bool) {
        if rotationControlView?.isAttachedToCropView == true {
            rotationControlView?.isHidden = isHidden
        }
    }
    
    private func imageStatusChanged() -> Bool {
        if viewModel.getTotalRadians() != 0 {
            return true
        }
        
        if forceFixedRatio {
            if checkForForceFixedRatioFlag {
                checkForForceFixedRatioFlag = false
                return cropWorkbenchView.zoomScale != 1
            }
        }
        
        if !isTheSamePoint(point1: getImageLeftTopAnchorPoint(), point2: .zero) {
            return true
        }
        
        if !isTheSamePoint(point1: getImageRightBottomAnchorPoint(), point2: CGPoint(x: 1, y: 1)) {
            return true
        }
        
        return false
    }
    
    private func checkImageStatusChanged() {
        if imageStatusChanged() {
            delegate?.cropViewDidBecomeResettable(self)
        } else {
            delegate?.cropViewDidBecomeUnResettable(self)
        }
    }
        
    private func setupCropWorkbenchView() {
        cropWorkbenchView.touchesBegan = { [weak self] in
            self?.viewModel.setTouchImageStatus()
        }
        
        cropWorkbenchView.touchesEnded = { [weak self] in
            self?.viewModel.setBetweenOperationStatus()
        }
        
        cropWorkbenchView.delegate = self
        addSubview(cropWorkbenchView)
        
        if cropViewConfig.minimumZoomScale > 1 {
            cropWorkbenchView.zoomScale = cropViewConfig.minimumZoomScale
        }
    }
    
    private func setupCropAuxiliaryIndicatorView() {
        cropAuxiliaryIndicatorView.isUserInteractionEnabled = false
        cropAuxiliaryIndicatorView.gridHidden = true
        addSubview(cropAuxiliaryIndicatorView)
    }
    
    /** This function is for correct flips. If rotating angle is exact ±45 degrees,
     the flip behaviour will be incorrect. So we need to limit the rotating angle. */
    private func clampAngle(_ angle: Angle) -> Angle {
        let errorMargin = 1e-10
        let rotationLimit = Constants.rotationDegreeLimit
        
        return angle.degrees > 0
        ? min(angle, Angle(degrees: rotationLimit - errorMargin))
        : max(angle, Angle(degrees: -rotationLimit + errorMargin))
    }
    
    private func setupRotationDialIfNeeded() {
        guard let rotationControlView = rotationControlView else {
            return
        }
        
        rotationControlView.reset()
        rotationControlView.isUserInteractionEnabled = true
        
        rotationControlView.didUpdateRotationValue = { [unowned self] angle in
            self.viewModel.setTouchRotationBoardStatus()
            self.viewModel.setRotatingStatus(by: clampAngle(angle))
        }
        
        rotationControlView.didFinishRotation = { [unowned self] in
            if !self.viewModel.needCrop() {
                self.delegate?.cropViewDidEndResize(self)
            }
            self.viewModel.setBetweenOperationStatus()
        }
        
        if rotationControlView.isAttachedToCropView {
            let boardLength = min(bounds.width, bounds.height) * rotationControlView.getLengthRatio()
            let dialFrame = CGRect(x: 0,
                                   y: 0,
                                   width: boardLength,
                                   height: cropViewConfig.rotationControlViewHeight)
            
            rotationControlView.setupUI(withAllowableFrame: dialFrame)
        }
        
        if let rotationDial = rotationControlView as? RotationDialProtocol {
            rotationDial.setRotationCenter(by: cropAuxiliaryIndicatorView.center, of: self)
        }
        
        rotationControlView.updateRotationValue(by: Angle(radians: viewModel.radians))
        viewModel.setBetweenOperationStatus()
        
        adaptRotationControlViewToCropBoxIfNeeded()
        rotationControlView.bringSelfToFront()
    }
    
    private func adaptRotationControlViewToCropBoxIfNeeded() {
        guard let rotationControlView = rotationControlView,
              rotationControlView.isAttachedToCropView else { return }
        
        if Orientation.treatAsPortrait {
            rotationControlView.transform = CGAffineTransform(rotationAngle: 0)
            rotationControlView.frame.origin.x = cropAuxiliaryIndicatorView.frame.origin.x +
            (cropAuxiliaryIndicatorView.frame.width - rotationControlView.frame.width) / 2
            rotationControlView.frame.origin.y = cropAuxiliaryIndicatorView.frame.maxY
        } else if Orientation.isLandscapeRight {
            rotationControlView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            rotationControlView.frame.origin.x = cropAuxiliaryIndicatorView.frame.maxX
            rotationControlView.frame.origin.y = cropAuxiliaryIndicatorView.frame.origin.y +
            (cropAuxiliaryIndicatorView.frame.height - rotationControlView.frame.height) / 2
        } else if Orientation.isLandscapeLeft {
            rotationControlView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            rotationControlView.frame.origin.x = cropAuxiliaryIndicatorView.frame.minX - rotationControlView.frame.width
            rotationControlView.frame.origin.y = cropAuxiliaryIndicatorView.frame.origin.y +
            (cropAuxiliaryIndicatorView.frame.height - rotationControlView.frame.height) / 2
        }
        
        rotationControlView.handleDeviceRotation()
    }
    
    private func confineTouchPoint(_ touchPoint: CGPoint, in rect: CGRect) -> CGPoint {
        var confinedPoint = touchPoint
        
        // Get the frame dimensions
        let rectWidth = rect.size.width
        let rectHeight = rect.size.height
        
        // Check if the touch point is outside the frame
        if touchPoint.x < rect.origin.x {
            confinedPoint.x = rect.origin.x
        } else if touchPoint.x > (rect.origin.x + rectWidth) {
            confinedPoint.x = rect.origin.x + rectWidth
        }
        
        if touchPoint.y < rect.origin.y {
            confinedPoint.y = rect.origin.y
        } else if touchPoint.y > (rect.origin.y + rectHeight) {
            confinedPoint.y = rect.origin.y + rectHeight
        }
        
        return confinedPoint
    }
    
    func updateCropBoxFrame(withTouchPoint touchPoint: CGPoint) {
        let imageContainerRect = imageContainer.convert(imageContainer.bounds, to: self)
        let imageFrame = CGRect(x: cropWorkbenchView.frame.origin.x - cropWorkbenchView.contentOffset.x,
                                y: cropWorkbenchView.frame.origin.y - cropWorkbenchView.contentOffset.y,
                                width: imageContainerRect.size.width,
                                height: imageContainerRect.size.height)
        
        let touchPoint = confineTouchPoint(touchPoint, in: imageFrame)
        let contentBounds = getContentBounds()
        let cropViewMinimumBoxSize = cropViewConfig.minimumCropBoxSize
        let newCropBoxFrame = viewModel.getNewCropBoxFrame(withTouchPoint: touchPoint,
                                                           andContentFrame: contentBounds,
                                                           aspectRatioLockEnabled: aspectRatioLockEnabled)
        
        guard newCropBoxFrame.width >= cropViewMinimumBoxSize
                && newCropBoxFrame.height >= cropViewMinimumBoxSize else {
            return
        }
        
        if imageContainer.contains(rect: newCropBoxFrame, fromView: self, tolerance: 0.5) {
            viewModel.cropBoxFrame = newCropBoxFrame
        } else {
            if aspectRatioLockEnabled {
                return
            }
            
            let minX = max(viewModel.cropBoxFrame.minX, newCropBoxFrame.minX)
            let minY = max(viewModel.cropBoxFrame.minY, newCropBoxFrame.minY)
            let maxX = min(viewModel.cropBoxFrame.maxX, newCropBoxFrame.maxX)
            let maxY = min(viewModel.cropBoxFrame.maxY, newCropBoxFrame.maxY)
            
            var rect: CGRect
            
            rect = CGRect(x: minX, y: minY, width: newCropBoxFrame.width, height: maxY - minY)
            if imageContainer.contains(rect: rect, fromView: self, tolerance: 0.5) {
                viewModel.cropBoxFrame = rect
                return
            }
            
            rect = CGRect(x: minX, y: minY, width: maxX - minX, height: newCropBoxFrame.height)
            if imageContainer.contains(rect: rect, fromView: self, tolerance: 0.5) {
                viewModel.cropBoxFrame = rect
                return
            }
            
            rect = CGRect(x: newCropBoxFrame.minX, y: minY, width: newCropBoxFrame.width, height: maxY - minY)
            if imageContainer.contains(rect: rect, fromView: self, tolerance: 0.5) {
                viewModel.cropBoxFrame = rect
                return
            }
            
            rect = CGRect(x: minX, y: newCropBoxFrame.minY, width: maxX - minX, height: newCropBoxFrame.height)
            if imageContainer.contains(rect: rect, fromView: self, tolerance: 0.5) {
                viewModel.cropBoxFrame = rect
                return
            }
            
            viewModel.cropBoxFrame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }
}

// MARK: - Adjust UI
extension CropView {
    func resetComponents() {
        cropMaskViewManager.setup(in: self, cropRatio: CGFloat(getImageHorizontalToVerticalRatio()))
        
        viewModel.resetCropFrame(by: getInitialCropBoxRect())
        cropWorkbenchView.resetImageContent(by: viewModel.cropBoxFrame)
        cropAuxiliaryIndicatorView.bringSelfToFront()
        
        setupRotationDialIfNeeded()
        
        if aspectRatioLockEnabled {
            setFixedRatioCropBox()
        }
    }

    private func flipCropWorkbenchViewIfNeeded() {
        if viewModel.horizontallyFlip {
            let scale: CGFloat = viewModel.rotationType.isRotatedByMultiple180 ? -1 : 1
            cropWorkbenchView.transformScaleBy(xScale: scale, yScale: -scale)
        }
        
        if viewModel.verticallyFlip {
            let scale: CGFloat = viewModel.rotationType.isRotatedByMultiple180 ? 1 : -1
            cropWorkbenchView.transformScaleBy(xScale: scale, yScale: -scale)
        }
    }
    
    private func rotateCropWorkbenchView() {
        let totalRadians = viewModel.getTotalRadians()
        cropWorkbenchView.transform = CGAffineTransform(rotationAngle: totalRadians)
        flipCropWorkbenchViewIfNeeded()
        adjustWorkbenchView(by: totalRadians)
    }
    
    private func getInitialCropBoxRect() -> CGRect {
        guard image.size.width > 0 && image.size.height > 0 else {
            return .zero
        }
        
        let outsideRect = getContentBounds()
        let insideRect: CGRect
        
        if viewModel.isUpOrUpsideDown() {
            insideRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        } else {
            insideRect = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
        }
        
        return GeometryHelper.getInscribeRect(fromOutsideRect: outsideRect, andInsideRect: insideRect)
    }
    
    func zoomIn() {
        cropWorkbenchView.zoomIn(by: cropViewConfig.keyboardZoomScaleFactor)
    }

    func zoomOut() {
        cropWorkbenchView.zoomOut(by: cropViewConfig.keyboardZoomScaleFactor)
    }
    
    func getContentBounds() -> CGRect {
        let cropViewPadding = cropViewConfig.padding
        
        let rect = self.bounds
        var contentRect = CGRect.zero
        
        var rotationControlViewHeight: CGFloat = 0
        
        if cropViewConfig.showAttachedRotationControlView && rotationControlView?.isAttachedToCropView == true {
            rotationControlViewHeight = cropViewConfig.rotationControlViewHeight
        }
        
        if Orientation.treatAsPortrait {
            contentRect.origin.x = rect.origin.x + cropViewPadding
            contentRect.origin.y = rect.origin.y + cropViewPadding
            
            contentRect.size.width = rect.width - 2 * cropViewPadding
            contentRect.size.height = rect.height - 2 * cropViewPadding - rotationControlViewHeight
        } else if Orientation.isLandscape {
            contentRect.size.width = rect.width - 2 * cropViewPadding - rotationControlViewHeight
            contentRect.size.height = rect.height - 2 * cropViewPadding
            
            contentRect.origin.y = rect.origin.y + cropViewPadding
            if Orientation.isLandscapeRight {
                contentRect.origin.x = rect.origin.x + cropViewPadding
            } else {
                contentRect.origin.x = rect.origin.x + cropViewPadding + rotationControlViewHeight
            }
        }
        
        return contentRect
    }
    
    private func getImageLeftTopAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.cropLeftTopOnImage
        }
        
        let leftTopPoint = cropAuxiliaryIndicatorView.convert(CGPoint(x: 0, y: 0), to: imageContainer)
        let point = CGPoint(x: leftTopPoint.x / imageContainer.bounds.width, y: leftTopPoint.y / imageContainer.bounds.height)
        return point
    }
    
    private func getImageRightBottomAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.cropRightBottomOnImage
        }
        
        let rightBottomPoint = cropAuxiliaryIndicatorView.convert(CGPoint(x: cropAuxiliaryIndicatorView.bounds.width,
                                                                          y: cropAuxiliaryIndicatorView.bounds.height),
                                                                  to: imageContainer)
        let point = CGPoint(x: rightBottomPoint.x / imageContainer.bounds.width, y: rightBottomPoint.y / imageContainer.bounds.height)
        return point
    }
    
    private func saveAnchorPoints() {
        viewModel.cropLeftTopOnImage = getImageLeftTopAnchorPoint()
        viewModel.cropRightBottomOnImage = getImageRightBottomAnchorPoint()
    }
    
    func adjustUIForNewCrop(contentRect: CGRect,
                            animation: Bool = true,
                            zoom: Bool = true,
                            completion: @escaping () -> Void) {
        
        guard viewModel.cropBoxFrame.size.width > 0 && viewModel.cropBoxFrame.size.height > 0 else {
            return
        }
        
        let scaleX = contentRect.width / viewModel.cropBoxFrame.size.width
        let scaleY = contentRect.height / viewModel.cropBoxFrame.size.height
        
        let scale = min(scaleX, scaleY)
        
        let newCropBounds = CGRect(x: 0, y: 0, width: viewModel.cropBoxFrame.width * scale, height: viewModel.cropBoxFrame.height * scale)
        
        let radians = viewModel.getTotalRadians()
        
        // calculate the new bounds of scroll view
        let newBoundWidth = abs(cos(radians)) * newCropBounds.size.width + abs(sin(radians)) * newCropBounds.size.height
        let newBoundHeight = abs(sin(radians)) * newCropBounds.size.width + abs(cos(radians)) * newCropBounds.size.height
        
        guard newBoundWidth > 0 && newBoundWidth != .infinity
                && newBoundHeight > 0 && newBoundHeight != .infinity else {
            return
        }
        
        // calculate the zoom area of scroll view
        var scaleFrame = viewModel.cropBoxFrame
        
        let refContentWidth = abs(cos(radians)) * cropWorkbenchView.contentSize.width + abs(sin(radians)) * cropWorkbenchView.contentSize.height
        let refContentHeight = abs(sin(radians)) * cropWorkbenchView.contentSize.width + abs(cos(radians)) * cropWorkbenchView.contentSize.height
        
        if scaleFrame.width >= refContentWidth {
            scaleFrame.size.width = refContentWidth
        }
        
        if scaleFrame.height >= refContentHeight {
            scaleFrame.size.height = refContentHeight
        }
        
        let contentOffset = cropWorkbenchView.contentOffset
        let contentOffsetCenter = CGPoint(x: (contentOffset.x + cropWorkbenchView.bounds.width / 2),
                                          y: (contentOffset.y + cropWorkbenchView.bounds.height / 2))
        
        cropWorkbenchView.bounds = CGRect(x: 0, y: 0, width: newBoundWidth, height: newBoundHeight)
        
        let newContentOffset = CGPoint(x: (contentOffsetCenter.x - newBoundWidth / 2),
                                       y: (contentOffsetCenter.y - newBoundHeight / 2))
        cropWorkbenchView.contentOffset = newContentOffset
        
        let newCropBoxFrame = GeometryHelper.getInscribeRect(fromOutsideRect: contentRect, andInsideRect: viewModel.cropBoxFrame)
        
        func updateUI(by newCropBoxFrame: CGRect, and scaleFrame: CGRect) {
            viewModel.cropBoxFrame = newCropBoxFrame
            
            if zoom {
                let zoomRect = convert(scaleFrame,
                                       to: cropWorkbenchView.imageContainer)
                cropWorkbenchView.zoom(to: zoomRect, animated: false)
            }
            cropWorkbenchView.updateContentOffset()
            makeSureImageContainsCropOverlay()
        }
        
        if animation {
            UIView.animate(withDuration: 0.25, animations: {
                updateUI(by: newCropBoxFrame, and: scaleFrame)
            }, completion: {_ in
                completion()
            })
        } else {
            updateUI(by: newCropBoxFrame, and: scaleFrame)
            completion()
        }
        
        isManuallyZoomed = true
    }
    
    func makeSureImageContainsCropOverlay() {
        if !imageContainer.contains(rect: cropAuxiliaryIndicatorView.frame, fromView: self, tolerance: 0.25) {
            cropWorkbenchView.zoomScaleToBound(animated: true)
        }
    }
    
    private func adjustWorkbenchView(by radians: CGFloat) {
        let width = abs(cos(radians)) * cropAuxiliaryIndicatorView.frame.width + abs(sin(radians)) * cropAuxiliaryIndicatorView.frame.height
        let height = abs(sin(radians)) * cropAuxiliaryIndicatorView.frame.width + abs(cos(radians)) * cropAuxiliaryIndicatorView.frame.height
        
        cropWorkbenchView.updateLayout(byNewSize: CGSize(width: width, height: height))
        
        if !isManuallyZoomed || cropWorkbenchView.shouldScale() {
            cropWorkbenchView.zoomScaleToBound(animated: false)
            isManuallyZoomed = false
        } else {
            cropWorkbenchView.updateMinZoomScale()
        }
        
        cropWorkbenchView.updateContentOffset()
    }
    
    func updatePositionFor90Rotation(by radians: CGFloat) {
        func adjustScrollViewForNormalRatio(by radians: CGFloat) -> CGFloat {
            let width = abs(cos(radians)) * cropAuxiliaryIndicatorView.frame.width + abs(sin(radians)) * cropAuxiliaryIndicatorView.frame.height
            let height = abs(sin(radians)) * cropAuxiliaryIndicatorView.frame.width + abs(cos(radians)) * cropAuxiliaryIndicatorView.frame.height
            
            let newSize: CGSize
            if viewModel.rotationType.isRotatedByMultiple180 {
                newSize = CGSize(width: width, height: height)
            } else {
                newSize = CGSize(width: height, height: width)
            }
            
            let scale = newSize.width / cropWorkbenchView.bounds.width
            cropWorkbenchView.updateLayout(byNewSize: newSize)
            return scale
        }
        
        let scale = adjustScrollViewForNormalRatio(by: radians)
        
        let newZoomScale = cropWorkbenchView.zoomScale * scale
        cropWorkbenchView.minimumZoomScale = newZoomScale
        cropWorkbenchView.zoomScale = newZoomScale
        
        cropWorkbenchView.updateContentOffset()
    }
}

// MARK: - internal API
extension CropView {
    func asyncCrop(_ image: UIImage, completion: @escaping (CropOutput) -> Void) {
        let cropInfo = getCropInfo()
        let cropOutput = (image.crop(by: cropInfo), makeTransformation(), cropInfo)
        
        DispatchQueue.global(qos: .userInteractive).async {
            let maskedCropOutput = self.addImageMask(to: cropOutput)
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                completion(maskedCropOutput)
            }
        }
    }
    
    public func makeCropState() -> CropState {
        return CropState(
            rotationType: viewModel.rotationType,
            degrees: viewModel.degrees,
            aspectRatioLockEnabled: aspectRatioLockEnabled,
            aspectRato: viewModel.fixedImageRatio,
            flipOddTimes: flipOddTimes,
            transformation: makeTransformation()
        )
    }
    
    func makeTransformation() -> Transformation {
        Transformation(
            offset: cropWorkbenchView.contentOffset,
            rotation: getTotalRadians(),
            scale: cropWorkbenchView.zoomScale,
            isManuallyZoomed: isManuallyZoomed,
            initialMaskFrame: getInitialCropBoxRect(),
            maskFrame: cropAuxiliaryIndicatorView.frame,
            cropWorkbenchViewBounds: cropWorkbenchView.bounds,
            horizontallyFlipped: viewModel.horizontallyFlip,
            verticallyFlipped: viewModel.verticallyFlip
        )
    }
    
    func addImageMask(to cropOutput: CropOutput) -> CropOutput {
        let (croppedImage, transformation, cropInfo) = cropOutput
        
        guard let croppedImage = croppedImage else {
            assertionFailure("croppedImage should not be nil")
            return cropOutput
        }
        
        switch cropViewConfig.cropShapeType {
        case .rect,
                .square,
                .circle(maskOnly: true),
                .roundedRect(_, maskOnly: true),
                .path(_, maskOnly: true),
                .diamond(maskOnly: true),
                .heart(maskOnly: true),
                .polygon(_, _, maskOnly: true):
            
            let outputImage: UIImage?
            if cropViewConfig.cropBorderWidth > 0 {
                outputImage = croppedImage.rectangleMasked(borderWidth: cropViewConfig.cropBorderWidth,
                                                           borderColor: cropViewConfig.cropBorderColor)
            } else {
                outputImage = croppedImage
            }
            
            return (outputImage, transformation, cropInfo)
        case .ellipse:
            return (croppedImage.ellipseMasked(borderWidth: cropViewConfig.cropBorderWidth,
                                               borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .circle:
            return (croppedImage.ellipseMasked(borderWidth: cropViewConfig.cropBorderWidth,
                                               borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .roundedRect(let radiusToShortSide, maskOnly: false):
            let radius = min(croppedImage.size.width, croppedImage.size.height) * radiusToShortSide
            return (croppedImage.roundRect(radius,
                                           borderWidth: cropViewConfig.cropBorderWidth,
                                           borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .path(let points, maskOnly: false):
            return (croppedImage.clipPath(points,
                                          borderWidth: cropViewConfig.cropBorderWidth,
                                          borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .diamond(maskOnly: false):
            let points = [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)]
            return (croppedImage.clipPath(points,
                                          borderWidth: cropViewConfig.cropBorderWidth,
                                          borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .heart(maskOnly: false):
            return (croppedImage.heart(borderWidth: cropViewConfig.cropBorderWidth,
                                       borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        case .polygon(let sides, let offset, maskOnly: false):
            let points = polygonPointArray(sides: sides, originX: 0.5, originY: 0.5, radius: 0.5, offset: 90 + offset)
            return (croppedImage.clipPath(points,
                                          borderWidth: cropViewConfig.cropBorderWidth,
                                          borderColor: cropViewConfig.cropBorderColor),
                    transformation,
                    cropInfo)
        }
    }
    
    func getTotalRadians() -> CGFloat {
        return viewModel.getTotalRadians()
    }
    
    func setFixedRatioCropBox(zoom: Bool = true, cropBox: CGRect? = nil) {
        let refCropBox = cropBox ?? getInitialCropBoxRect()
        let imageHorizontalToVerticalRatio = ImageHorizontalToVerticalRatio(ratio: getImageHorizontalToVerticalRatio())
        viewModel.setCropBoxFrame(by: refCropBox, for: imageHorizontalToVerticalRatio)
        
        let contentRect = getContentBounds()
        adjustUIForNewCrop(contentRect: contentRect, animation: false, zoom: zoom) { [weak self] in
            guard let self = self else { return }
            if self.forceFixedRatio {
                self.checkForForceFixedRatioFlag = true
            }
            self.viewModel.setBetweenOperationStatus()
        }
        
        adaptRotationControlViewToCropBoxIfNeeded()
        cropWorkbenchView.updateMinZoomScale()
    }
    
    private func flip(isHorizontal: Bool = true, animated: Bool = true) {
        var scaleX: CGFloat = 1
        var scaleY: CGFloat = 1
        
        if isHorizontal {
            if viewModel.rotationType.isRotatedByMultiple180 {
                scaleX = -scaleX
            } else {
                scaleY = -scaleY
            }
        } else {
            if viewModel.rotationType.isRotatedByMultiple180 {
                scaleY = -scaleY
            } else {
                scaleX = -scaleX
            }
        }
        
        func flip() {
            flipOddTimes.toggle()
            
            let flipTransform = cropWorkbenchView.transform.scaledBy(x: scaleX, y: scaleY)
            let coff: CGFloat = flipOddTimes ? 2 : -2
            cropWorkbenchView.transform = flipTransform.rotated(by: coff*viewModel.radians)
            
            viewModel.degrees *= -1
            rotationControlView?.updateRotationValue(by: Angle(degrees: viewModel.degrees))
        }
        
        if animated {
            UIView.animate(withDuration: 0.5) {
                flip()
            }
        } else {
            flip()
        }
    }
}

extension CropView: CropViewProtocol {
    private func setForceFixedRatio(by presetFixedRatioType: PresetFixedRatioType) {
        switch presetFixedRatioType {
        case .alwaysUsingOnePresetFixedRatio:
            forceFixedRatio = true
        case .canUseMultiplePresetFixedRatio(let defaultRatio):
            forceFixedRatio = defaultRatio > 0
        }
    }
    
    func initialSetup(delegate: CropViewDelegate, presetFixedRatioType: PresetFixedRatioType) {
        self.delegate = delegate
        setViewDefaultProperties()
        setForceFixedRatio(by: presetFixedRatioType)
    }
    
    func getRatioType(byImageIsOriginalHorizontal isHorizontal: Bool) -> RatioType {
        return viewModel.getRatioType(byImageIsOriginalHorizontal: isHorizontal)
    }
    
    func getImageHorizontalToVerticalRatio() -> Double {
        if viewModel.rotationType.isRotatedByMultiple180 {
            return Double(image.horizontalToVerticalRatio())
        } else {
            return Double(1 / image.horizontalToVerticalRatio())
        }
    }
    
    func prepareForViewWillTransition() {
        viewModel.setDegree90RotatingStatus()
        saveAnchorPoints()
    }
    
    func handleViewWillTransition() {
        viewModel.resetCropFrame(by: getInitialCropBoxRect())
        
        cropWorkbenchView.transform = CGAffineTransform(scaleX: 1, y: 1)
        cropWorkbenchView.reset(by: viewModel.cropBoxFrame)
        
        rotateCropWorkbenchView()
        
        if viewModel.cropRightBottomOnImage != .zero {
            var leftTopPoint = CGPoint(x: viewModel.cropLeftTopOnImage.x * imageContainer.bounds.width,
                                       y: viewModel.cropLeftTopOnImage.y * imageContainer.bounds.height)
            var rightBottomPoint = CGPoint(x: viewModel.cropRightBottomOnImage.x * imageContainer.bounds.width,
                                           y: viewModel.cropRightBottomOnImage.y * imageContainer.bounds.height)
            
            leftTopPoint = imageContainer.convert(leftTopPoint, to: self)
            rightBottomPoint = imageContainer.convert(rightBottomPoint, to: self)
            
            let rect = CGRect(origin: leftTopPoint,
                              size: CGSize(width: rightBottomPoint.x - leftTopPoint.x,
                                           height: rightBottomPoint.y - leftTopPoint.y))
            viewModel.cropBoxFrame = rect
            
            let contentRect = getContentBounds()
            
            adjustUIForNewCrop(contentRect: contentRect) { [weak self] in
                self?.viewModel.setBetweenOperationStatus()
            }
        }
    }
    
    func setFixedRatio(_ ratio: Double, zoom: Bool = true, presetFixedRatioType: PresetFixedRatioType) {
       
        aspectRatioLockEnabled = true
        
        if viewModel.fixedImageRatio != CGFloat(ratio) {
            viewModel.fixedImageRatio = CGFloat(ratio)
            
            setForceFixedRatio(by: presetFixedRatioType)
            
            if forceFixedRatio {
                setFixedRatioCropBox(zoom: zoom)
            } else {
                UIView.animate(withDuration: 0.5) {
                    self.setFixedRatioCropBox(zoom: zoom)
                }
            }
        }
    }
    
    func rotateBy90(withRotateType rotateType: RotateBy90DegreeType, completion: @escaping () -> Void = {}) {
        viewModel.setDegree90RotatingStatus()
        
        var newRotateType = rotateType
        
        if viewModel.horizontallyFlip {
            newRotateType.toggle()
        }
        
        if viewModel.verticallyFlip {
            newRotateType.toggle()
        }
        
        func handleRotateAnimation() {
            if cropViewConfig.rotateCropBoxFor90DegreeRotation {
                var rect = cropAuxiliaryIndicatorView.frame
                rect.size.width = cropAuxiliaryIndicatorView.frame.height
                rect.size.height = cropAuxiliaryIndicatorView.frame.width
                
                let newRect = GeometryHelper.getInscribeRect(fromOutsideRect: getContentBounds(), andInsideRect: rect)
                viewModel.cropBoxFrame = newRect
            }
            
            let rotateAngle = newRotateType == .clockwise ? CGFloat.pi / 2 : -CGFloat.pi / 2
            cropWorkbenchView.transform = cropWorkbenchView.transform.rotated(by: rotateAngle)
            
            if cropViewConfig.rotateCropBoxFor90DegreeRotation {
                updatePositionFor90Rotation(by: rotateAngle + viewModel.radians)
            } else {
                adjustWorkbenchView(by: rotateAngle + viewModel.radians)
            }
        }
        
        func handleRotateCompletion() {
            cropWorkbenchView.updateMinZoomScale()
            viewModel.rotateBy90(withRotateType: newRotateType)
            viewModel.setBetweenOperationStatus()
            completion()
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            handleRotateAnimation()
        }, completion: { _ in
            handleRotateCompletion()
        })
    }
    
    func handleAlterCropper90Degree() {
        let ratio = Double(cropAuxiliaryIndicatorView.frame.height / cropAuxiliaryIndicatorView.frame.width)
        
        viewModel.fixedImageRatio = CGFloat(ratio)
        
        UIView.animate(withDuration: 0.5) {
            self.setFixedRatioCropBox()
        }
    }
    
    func handlePresetFixedRatio(_ ratio: Double, transformation: Transformation) {
        aspectRatioLockEnabled = true
        
        if ratio == 0 {
            viewModel.fixedImageRatio = transformation.maskFrame.width / transformation.maskFrame.height
        } else {
            viewModel.fixedImageRatio = CGFloat(ratio)
            setFixedRatioCropBox(zoom: false, cropBox: viewModel.cropBoxFrame)
        }
    }
    
    func setFreeCrop() {
        aspectRatioLockEnabled = false
        viewModel.fixedImageRatio = -1
    }
    
    public func applyCropState(with cropState: CropState) {
        viewModel.rotationType = .none
        viewModel.horizontallyFlip = cropState.transformation.horizontallyFlipped
        viewModel.verticallyFlip = cropState.transformation.verticallyFlipped
        viewModel.fixedImageRatio = cropState.aspectRato
        flipOddTimes = cropState.flipOddTimes
        
        var newTransform = getTransformInfo(byTransformInfo: cropState.transformation)
        
        if flipOddTimes {
            let localRotation = newTransform.rotation.truncatingRemainder(dividingBy: .pi/2)
            let rotation90s = newTransform.rotation - localRotation
            newTransform.rotation = -rotation90s + localRotation
        }
        
        if newTransform.maskFrame != .zero {
             viewModel.cropBoxFrame = newTransform.maskFrame
        }
        
        transform(byTransformInfo: newTransform)
        
        viewModel.degrees = cropState.degrees
        viewModel.rotationType = cropState.rotationType
        aspectRatioLockEnabled = cropState.aspectRatioLockEnabled
    }
    
    func transform(byTransformInfo transformation: Transformation, isUpdateRotationControlView: Bool = true) {
        
        viewModel.setRotatingStatus(by: Angle(radians: transformation.rotation))
        
        if transformation.cropWorkbenchViewBounds != .zero {
            cropWorkbenchView.bounds = transformation.cropWorkbenchViewBounds
        }
        
        isManuallyZoomed = transformation.isManuallyZoomed
        cropWorkbenchView.zoomScale = transformation.scale
        cropWorkbenchView.contentOffset = transformation.offset
        
        viewModel.setBetweenOperationStatus()
        
        if transformation.maskFrame != .zero {
            viewModel.cropBoxFrame = transformation.maskFrame
        }
        
        if isUpdateRotationControlView {
            rotationControlView?.updateRotationValue(by: Angle(radians: viewModel.radians))
            adaptRotationControlViewToCropBoxIfNeeded()
        }
    }
    
    func getTransformInfo(byTransformInfo transformInfo: Transformation) -> Transformation {
        let cropFrame = viewModel.cropBoxOriginFrame
        let contentBound = getContentBounds()
        
        let adjustScale: CGFloat
        var maskFrameWidth: CGFloat
        var maskFrameHeight: CGFloat
        
        if transformInfo.maskFrame.height / transformInfo.maskFrame.width >= contentBound.height / contentBound.width {
            
            maskFrameHeight = contentBound.height
            maskFrameWidth = transformInfo.maskFrame.width / transformInfo.maskFrame.height * maskFrameHeight
            adjustScale = maskFrameHeight / transformInfo.maskFrame.height
            
        } else {
            
            maskFrameWidth = contentBound.width
            maskFrameHeight = transformInfo.maskFrame.height / transformInfo.maskFrame.width * maskFrameWidth
            adjustScale = maskFrameWidth / transformInfo.maskFrame.width
            
        }
        
        var newTransform = transformInfo
        
        newTransform.offset = CGPoint(x: transformInfo.offset.x * adjustScale,
                                      y: transformInfo.offset.y * adjustScale)
        
        newTransform.maskFrame = CGRect(x: cropFrame.origin.x + (cropFrame.width - maskFrameWidth) / 2,
                                        y: cropFrame.origin.y + (cropFrame.height - maskFrameHeight) / 2,
                                        width: maskFrameWidth,
                                        height: maskFrameHeight)
        newTransform.cropWorkbenchViewBounds = CGRect(x: transformInfo.cropWorkbenchViewBounds.origin.x * adjustScale,
                                                      y: transformInfo.cropWorkbenchViewBounds.origin.y * adjustScale,
                                                      width: transformInfo.cropWorkbenchViewBounds.width * adjustScale,
                                                      height: transformInfo.cropWorkbenchViewBounds.height * adjustScale)
        
        return newTransform
    }
    
    func getTransformInfo(byNormalizedInfo normalizedInfo: CGRect) -> Transformation {
        let cropFrame = viewModel.cropBoxFrame
        
        let scale: CGFloat = min(1/normalizedInfo.width, 1/normalizedInfo.height)
        
        var offset = cropFrame.origin
        offset.x = cropFrame.width * normalizedInfo.origin.x * scale
        offset.y = cropFrame.height * normalizedInfo.origin.y * scale
        
        var maskFrame = cropFrame
        
        if normalizedInfo.width > normalizedInfo.height {
            let adjustScale = 1 / normalizedInfo.width
            maskFrame.size.height = normalizedInfo.height * cropFrame.height * adjustScale
            maskFrame.origin.y += (cropFrame.height - maskFrame.height) / 2
        } else if normalizedInfo.width < normalizedInfo.height {
            let adjustScale = 1 / normalizedInfo.height
            maskFrame.size.width = normalizedInfo.width * cropFrame.width * adjustScale
            maskFrame.origin.x += (cropFrame.width - maskFrame.width) / 2
        }
        
        let isManuallyZoomed = (scale != 1.0)
        let transformation = Transformation(offset: offset,
                                            rotation: 0,
                                            scale: scale,
                                            isManuallyZoomed: isManuallyZoomed,
                                            initialMaskFrame: .zero,
                                            maskFrame: maskFrame,
                                            cropWorkbenchViewBounds: .zero,
                                            horizontallyFlipped: viewModel.horizontallyFlip,
                                            verticallyFlipped: viewModel.verticallyFlip)
        return transformation
    }
    
    func processPresetTransformation(completion: (Transformation) -> Void) {
        switch cropViewConfig.presetTransformationType {
        case .presetInfo(let transformInfo):
            viewModel.horizontallyFlip = transformInfo.horizontallyFlipped
            viewModel.verticallyFlip = transformInfo.verticallyFlipped
            
            if transformInfo.horizontallyFlipped {
                flipOddTimes.toggle()
            }
            
            if transformInfo.verticallyFlipped {
                flipOddTimes.toggle()
            }
            
            var newTransform = getTransformInfo(byTransformInfo: transformInfo)
            
            // The first transform is just for retrieving the final cropBoxFrame
            transform(byTransformInfo: newTransform, isUpdateRotationControlView: false)
            
            // The second transform is for adjusting the scale of transformInfo
            let adjustScale = (viewModel.cropBoxFrame.width / viewModel.cropBoxOriginFrame.width)
            / (transformInfo.maskFrame.width / transformInfo.initialMaskFrame.width)
            newTransform.scale *= adjustScale
            transform(byTransformInfo: newTransform)
            completion(transformInfo)
        case .presetNormalizedInfo(let normalizedInfo):
            let transformInfo = getTransformInfo(byNormalizedInfo: normalizedInfo)
            transform(byTransformInfo: transformInfo)
            cropWorkbenchView.frame = transformInfo.maskFrame
            completion(transformInfo)
        case .none:
            break
        }
    }
    
    func horizontallyFlip() {
        viewModel.horizontallyFlip.toggle()
        flip(isHorizontal: true)
        checkImageStatusChanged()
    }
    
    func verticallyFlip() {
        viewModel.verticallyFlip.toggle()
        flip(isHorizontal: false)
        checkImageStatusChanged()
    }
    
    func reset() {
        flipOddTimes = false
        aspectRatioLockEnabled = forceFixedRatio
        viewModel.reset(forceFixedRatio: forceFixedRatio)
        
        resetComponents()
        
        delegate?.cropViewDidBecomeUnResettable(self)
        delegate?.cropViewDidEndResize(self)
    }
    
    func crop() -> CropOutput {
        return crop(image)
    }
    
    func crop(_ image: UIImage) -> CropOutput {
        let cropInfo = getCropInfo()
        let cropOutput = (image.crop(by: cropInfo), makeTransformation(), cropInfo)
        return addImageMask(to: cropOutput)
    }
    
    /// completion is called in the main thread
    func asyncCrop(completion: @escaping (CropOutput) -> Void ) {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        asyncCrop(image) { [weak self] cropOutput  in
            self?.activityIndicator.isHidden = true
            completion(cropOutput)
        }
    }
    
    func getCropInfo() -> CropInfo {
        let rect = imageContainer.convert(imageContainer.bounds,
                                          to: self)
        let point = rect.center
        let zeroPoint = cropAuxiliaryIndicatorView.center
        
        let translation =  CGPoint(x: (point.x - zeroPoint.x), y: (point.y - zeroPoint.y))
        
        var scaleX = cropWorkbenchView.zoomScale
        var scaleY = cropWorkbenchView.zoomScale
        
        if viewModel.horizontallyFlip {
            if viewModel.rotationType.isRotatedByMultiple180 {
                scaleX = -scaleX
            } else {
                scaleY = -scaleY
            }
        }
        
        if viewModel.verticallyFlip {
            if viewModel.rotationType.isRotatedByMultiple180 {
                scaleY = -scaleY
            } else {
                scaleX = -scaleX
            }
        }
        
        let totalRadians = getTotalRadians()
        let cropRegion = imageContainer.getCropRegion(withCropBoxFrame: viewModel.cropBoxFrame,
                                                      cropView: self)
        
        return CropInfo(
            translation: translation,
            rotation: totalRadians,
            scaleX: scaleX,
            scaleY: scaleY,
            cropSize: cropAuxiliaryIndicatorView.frame.size,
            imageViewSize: imageContainer.bounds.size,
            cropRegion: cropRegion
        )
    }
    
    func getExpectedCropImageSize() -> CGSize {
        image.getOutputCropImageSize(by: getCropInfo())
    }
    
    func rotate(by angle: Angle) {
        viewModel.setRotatingStatus(by: angle)
        rotationControlView?.updateRotationValue(by: angle)
    }
    
    func update(_ image: UIImage) {
        self.image = image
        imageContainer.update(image)
    }
}

extension UIActivityIndicatorView: ActivityIndicatorProtocol {
    
}
