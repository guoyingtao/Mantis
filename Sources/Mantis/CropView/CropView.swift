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
    func cropViewDidEndCrop(_ cropView: CropViewProtocol)
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
    
    var flipOddTimes = false
    
    /// The current rotation adjustment mode (straighten, horizontal skew, vertical skew)
    var currentRotationAdjustmentType: RotationAdjustmentType = .straighten
    
    /// Mutable state used to smooth and stabilize skew transforms.
    var skewState = SkewState()
    
    /// Whether the SlideDial is in withTypeSelector mode and handles type selection internally
    var slideDialHandlesTypeSelection: Bool {
        if let slideDial = rotationControlView as? SlideDial,
           case .withTypeSelector = slideDial.config.mode {
            return true
        }
        return false
    }
    
    /// Rotation type selector UI (Straighten | Horizontal | Vertical)
    lazy var rotationTypeSelector: RotationTypeSelector = {
        let selector = RotationTypeSelector()
        selector.delegate = self
        selector.appearanceMode = cropViewConfig.appearanceMode
        return selector
    }()
    
    lazy var activityIndicator: ActivityIndicatorProtocol = {
        let activityIndicator: ActivityIndicatorProtocol
        if let indicator = cropViewConfig.cropActivityIndicator {
            activityIndicator = indicator
        } else {
            let indicator = UIActivityIndicatorView(frame: .zero)
            indicator.color = AppearanceColorPreset.activityIndicatorColor(for: cropViewConfig.appearanceMode)
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
            cropAuxiliaryIndicatorView.gridLineNumberType = .crop
            cropAuxiliaryIndicatorView.gridHidden = false
        case .touchCropboxHandle(let tappedEdge):
            cropAuxiliaryIndicatorView.handleIndicatorHandleTouched(with: tappedEdge)
            toggleRotationControlViewIsNeeded(isHidden: true)
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
            // Keep rotation type selector visible and on top (only for external selector)
            if cropViewConfig.enablePerspectiveCorrection && !slideDialHandlesTypeSelection {
                layoutRotationTypeSelector()
                rotationTypeSelector.bringSelfToFront()
            }
        }
    }
    
    private func toggleRotationControlViewIsNeeded(isHidden: Bool) {
        if rotationControlView?.isAttachedToCropView == true {
            rotationControlView?.isHidden = isHidden
        }
    }
    
    func imageStatusChanged() -> Bool {
        if viewModel.getTotalRadians() != 0 {
            return true
        }
        
        if viewModel.horizontalSkewDegrees != 0 || viewModel.verticalSkewDegrees != 0 {
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
    
    func checkImageStatusChanged() {
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
    func clampAngle(_ angle: Angle) -> Angle {
        let errorMargin = 1e-10
        let rotationLimit = Constants.rotationDegreeLimit
        
        return angle.degrees > 0
        ? min(angle, Angle(degrees: rotationLimit - errorMargin))
        : max(angle, Angle(degrees: -rotationLimit + errorMargin))
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

    func rotateCropWorkbenchView() {
        let totalRadians = viewModel.getTotalRadians()
        cropWorkbenchView.transform = CGAffineTransform(rotationAngle: totalRadians)
        flipCropWorkbenchViewIfNeeded()

        // adjustWorkbenchView MUST run before applySkewTransformIfNeeded so that
        // cropWorkbenchView.bounds (which grows with rotation) is up-to-date when
        // computeSkewProjectionInputs reads it for the compensating scale.
        // Previously the reverse order caused the scale to be computed for stale
        // bounds, making updateContentInsetForSkew fall back to stale insets that
        // were too generous at combined skew + rotation angles.
        adjustWorkbenchView(by: totalRadians)

        let hasSkew = viewModel.horizontalSkewDegrees != 0 || viewModel.verticalSkewDegrees != 0
        if hasSkew {
            applySkewTransformIfNeeded()
            updateContentInsetForSkew()
        }
    }
    
    func getInitialCropBoxRect() -> CGRect {
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
}

// MARK: - CropViewProtocol
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
        let savedHSkew = viewModel.horizontalSkewDegrees
        let savedVSkew = viewModel.verticalSkewDegrees
        let hasSkew = savedHSkew != 0 || savedVSkew != 0
        if hasSkew {
            viewModel.horizontalSkewDegrees = 0
            viewModel.verticalSkewDegrees = 0
        }
        
        let savedIsManuallyZoomed = isManuallyZoomed
        
        // Check if the user has actually modified the crop region.
        // When anchor points are at their defaults ((0,0) and (1,1)),
        // the image is in its initial state and we can do a simple
        // full reset instead of the complex anchor-point restoration
        // which suffers from coordinate conversion drift.
        let anchorTolerance: CGFloat = 1e-3
        let isDefaultCropRegion =
            abs(viewModel.cropLeftTopOnImage.x) < anchorTolerance
            && abs(viewModel.cropLeftTopOnImage.y) < anchorTolerance
            && abs(viewModel.cropRightBottomOnImage.x - 1) < anchorTolerance
            && abs(viewModel.cropRightBottomOnImage.y - 1) < anchorTolerance
        
        if isDefaultCropRegion || viewModel.cropRightBottomOnImage == .zero {
            // Unmodified image — do a clean reset for the new orientation.
            viewModel.resetCropFrame(by: getInitialCropBoxRect())
            cropWorkbenchView.resetImageContent(by: viewModel.cropBoxFrame)
            
            let totalRadians = viewModel.getTotalRadians()
            if totalRadians != 0 {
                cropWorkbenchView.transform = CGAffineTransform(rotationAngle: totalRadians)
                flipCropWorkbenchViewIfNeeded()
                adjustWorkbenchView(by: totalRadians)
            }
            
            isManuallyZoomed = savedIsManuallyZoomed
            if hasSkew {
                viewModel.horizontalSkewDegrees = savedHSkew
                viewModel.verticalSkewDegrees = savedVSkew
                skewState.reset()
                applySkewTransformIfNeeded()
                updateContentInsetForSkew()
            }
            
            if aspectRatioLockEnabled {
                setFixedRatioCropBox()
            }
            
            viewModel.setBetweenOperationStatus()
        } else {
            // User has modified the crop — restore via anchor points.
            viewModel.resetCropFrame(by: getInitialCropBoxRect())
            
            cropWorkbenchView.transform = CGAffineTransform(scaleX: 1, y: 1)
            cropWorkbenchView.reset(by: viewModel.cropBoxFrame)
            
            rotateCropWorkbenchView()
            
            var leftTopPoint = CGPoint(x: viewModel.cropLeftTopOnImage.x * imageContainer.bounds.width,
                                       y: viewModel.cropLeftTopOnImage.y * imageContainer.bounds.height)
            var rightBottomPoint = CGPoint(x: viewModel.cropRightBottomOnImage.x * imageContainer.bounds.width,
                                           y: viewModel.cropRightBottomOnImage.y * imageContainer.bounds.height)
            
            // Position cropWorkbenchView's center at the new crop box center
            // so that imageContainer.convert produces correct coordinates.
            cropWorkbenchView.center = CGPoint(x: viewModel.cropBoxFrame.midX,
                                               y: viewModel.cropBoxFrame.midY)
            
            leftTopPoint = imageContainer.convert(leftTopPoint, to: self)
            rightBottomPoint = imageContainer.convert(rightBottomPoint, to: self)
            
            let rect = CGRect(origin: leftTopPoint,
                              size: CGSize(width: rightBottomPoint.x - leftTopPoint.x,
                                           height: rightBottomPoint.y - leftTopPoint.y))
            viewModel.cropBoxFrame = rect
            
            let contentRect = getContentBounds()
            
            adjustUIForNewCrop(contentRect: contentRect) { [weak self] in
                guard let self = self else { return }
                self.isManuallyZoomed = savedIsManuallyZoomed
                if hasSkew {
                    self.viewModel.horizontalSkewDegrees = savedHSkew
                    self.viewModel.verticalSkewDegrees = savedVSkew
                    self.skewState.reset()
                    self.applySkewTransformIfNeeded()
                    self.updateContentInsetForSkew()
                }
                self.viewModel.setBetweenOperationStatus()
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
    
    func reset() {
        flipOddTimes = false
        aspectRatioLockEnabled = forceFixedRatio
        viewModel.reset(forceFixedRatio: forceFixedRatio)
        
        // Reset skew state
        currentRotationAdjustmentType = .straighten
        skewState.reset()
        if slideDialHandlesTypeSelection {
            // SlideDial handles its own type button reset via its reset() method
        } else {
            rotationTypeSelector.reset()
        }
        cropWorkbenchView.layer.sublayerTransform = CATransform3DIdentity
        cropWorkbenchView.contentInset = .zero
        
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
    
    func update(_ image: UIImage) {
        self.image = image
        imageContainer.update(image)
    }
}

extension UIActivityIndicatorView: ActivityIndicatorProtocol {
    
}
