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
    
    /// The current rotation adjustment mode (straighten, horizontal skew, vertical skew)
    var currentRotationAdjustmentType: RotationAdjustmentType = .straighten
    
    /// Tracks the previous compensating scale to prevent single-frame spikes
    /// when switching between skew axes (e.g. vertical → horizontal).
    private var previousSkewScale: CGFloat = 1.0
    
    /// Tracks the previous contentInset for skew to rate-limit decreases.
    /// When certain combined angles cause the polygon test to fail transiently,
    /// this prevents insets from collapsing to zero in a single frame.
    private var previousSkewInset: UIEdgeInsets = .zero
    
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
        return selector
    }()
    
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
    
    private func imageStatusChanged() -> Bool {
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
            // Notify delegate on the first frame of each rotation gesture
            // so that previousCropState is captured for undo/redo.
            if self.viewModel.viewStatus != .touchRotationBoard {
                self.delegate?.cropViewDidBeginResize(self)
            }
            self.viewModel.setTouchRotationBoardStatus()
            
            switch self.currentRotationAdjustmentType {
            case .straighten:
                self.viewModel.setRotatingStatus(by: clampAngle(angle))
            case .horizontalSkew:
                let clamped = max(-PerspectiveTransformHelper.maxSkewDegrees,
                                  min(PerspectiveTransformHelper.maxSkewDegrees, angle.degrees))
                self.viewModel.horizontalSkewDegrees = clamped
                self.applySkewTransformIfNeeded()
                self.updateContentInsetForSkew()
            case .verticalSkew:
                let clamped = max(-PerspectiveTransformHelper.maxSkewDegrees,
                                  min(PerspectiveTransformHelper.maxSkewDegrees, angle.degrees))
                self.viewModel.verticalSkewDegrees = clamped
                self.applySkewTransformIfNeeded()
                self.updateContentInsetForSkew()
            }
        }
        
        rotationControlView.didFinishRotation = { [unowned self] in
            if !self.viewModel.needCrop() {
                self.delegate?.cropViewDidEndResize(self)
            }
            // After rotation ends, recalculate contentInset for the new geometry
            // so panning still works correctly when skew is active.
            self.updateContentInsetForSkew()
            self.makeSureImageContainsCropOverlay()
            self.viewModel.setBetweenOperationStatus()
        }
        
        // Hook up the type switch callback for SlideDial in withTypeSelector mode
        if let slideDial = rotationControlView as? SlideDial {
            slideDial.didSwitchAdjustmentType = { [unowned self] newType in
                self.currentRotationAdjustmentType = newType
                
                // Notify that rotation finished so CropView settles layout
                if !self.viewModel.needCrop() {
                    self.delegate?.cropViewDidEndResize(self)
                }
                self.viewModel.setBetweenOperationStatus()
            }
        }
        
        if rotationControlView.isAttachedToCropView {
            let boardLength = min(bounds.width, bounds.height) * rotationControlView.getLengthRatio()
            // withTypeSelector mode needs more height for the circular buttons above the ruler
            let controlHeight: CGFloat = slideDialHandlesTypeSelection
                ? max(cropViewConfig.rotationControlViewHeight, 120)
                : cropViewConfig.rotationControlViewHeight
            let dialFrame = CGRect(x: 0,
                                   y: 0,
                                   width: boardLength,
                                   height: controlHeight)
            
            rotationControlView.setupUI(withAllowableFrame: dialFrame)
        }
        
        if let rotationDial = rotationControlView as? RotationDialProtocol {
            rotationDial.setRotationCenter(by: cropAuxiliaryIndicatorView.center, of: self)
        }
        
        rotationControlView.updateRotationValue(by: Angle(radians: viewModel.radians))
        viewModel.setBetweenOperationStatus()
        
        adaptRotationControlViewToCropBoxIfNeeded()
        rotationControlView.bringSelfToFront()
        
        // Set up rotation type selector if enabled
        setupRotationTypeSelector()
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
        applySkewTransformIfNeeded()
        adjustWorkbenchView(by: totalRadians)
        
        // Keep content insets in sync with the changing geometry during rotation
        // so the crop overlay stays within the projected image area.
        if viewModel.horizontalSkewDegrees != 0 || viewModel.verticalSkewDegrees != 0 {
            updateContentInsetForSkew()
        }
    }
    
    /// Returns the effective skew degrees after accounting for flip state.
    /// The viewModel stores the user-facing (SlideDial-displayed) value;
    /// flipping mirrors the perspective, so the sign must be inverted for
    /// the axis that matches the flip direction.
    private var effectiveHorizontalSkewDegrees: CGFloat {
        var deg = viewModel.horizontalSkewDegrees
        if viewModel.horizontallyFlip { deg = -deg }
        return deg
    }
    
    private var effectiveVerticalSkewDegrees: CGFloat {
        var deg = viewModel.verticalSkewDegrees
        if viewModel.verticallyFlip { deg = -deg }
        return deg
    }
    
    /// Applies the perspective (3D) skew transform to the crop workbench view's layer.
    /// Includes an auto-computed compensating scale so the projected image
    /// always fully covers the visible area (no blank edges).
    private func applySkewTransformIfNeeded() {
        let hDeg = effectiveHorizontalSkewDegrees
        let vDeg = effectiveVerticalSkewDegrees
        
        if hDeg == 0 && vDeg == 0 {
            cropWorkbenchView.layer.sublayerTransform = CATransform3DIdentity
            cropWorkbenchView.contentInset = .zero
            previousSkewScale = 1.0
            previousSkewInset = .zero
        } else {
            let perspectiveTransform =
                PerspectiveTransformHelper.combinedSkewTransform3D(
                    horizontalDegrees: hDeg,
                    verticalDegrees: vDeg
                )
            
            let maxDeg = max(abs(hDeg), abs(vDeg))
            let normalizedAngle = min(maxDeg / PerspectiveTransformHelper.maxSkewDegrees, 1)
            let threshold = PerspectiveTransformHelper.translateThresholdDegrees
            let rawFactor = (maxDeg - threshold) / (PerspectiveTransformHelper.maxSkewDegrees - threshold)
            let factor = max(0, min(1, rawFactor))
            let safetyInset = (20 * factor) + (8 * factor * factor)
            let (cornerDisplacements, visibleCornerDisplacements, _, visibleTopLeft) =
                computeSkewProjectionInputs(safetyInset: safetyInset)
            // Compute compensating scale to prevent blank areas
            let rawScale = PerspectiveTransformHelper.computeCompensatingScale(
                imageCornerDisplacements: cornerDisplacements,
                visibleCornerDisplacements: visibleCornerDisplacements,
                perspectiveTransform: perspectiveTransform
            )
            let topLeftAdjust = max(0, -visibleTopLeft.y / max(cropAuxiliaryIndicatorView.bounds.height, 1))
            let topLeftScale = 1 + min(0.04, topLeftAdjust * 0.09) * normalizedAngle
            let safetyScale = 1 + (0.08 * factor) + (0.06 * factor * factor)
            var finalScale = rawScale * safetyScale * topLeftScale
            
            // Rate-limit scale changes to prevent single-frame spikes.
            // When switching skew axes, the binary search can produce an
            // anomalous value for one frame. Clamping prevents the jump.
            let maxChangeRatio: CGFloat = 0.03
            if previousSkewScale > 1.0 {
                let lower = previousSkewScale * (1 - maxChangeRatio)
                let upper = previousSkewScale * (1 + maxChangeRatio)
                finalScale = max(lower, min(upper, finalScale))
            }
            
            previousSkewScale = finalScale
            
            let scaledTransform = CATransform3DScale(perspectiveTransform, finalScale, finalScale, 1)
            cropWorkbenchView.layer.sublayerTransform = scaledTransform
        }
    }
    
    /// Recomputes contentInset for the current skew transform so the user
    /// can pan within the projected image area. Call this only when skew
    /// degrees actually change, NOT during every rotation frame.
    private func updateContentInsetForSkew() {
        let hDeg = effectiveHorizontalSkewDegrees
        let vDeg = effectiveVerticalSkewDegrees
        
        guard hDeg != 0 || vDeg != 0 else {
            cropWorkbenchView.contentInset = .zero
            previousSkewInset = .zero
            return
        }
        
        let transform = cropWorkbenchView.layer.sublayerTransform
        guard !CATransform3DIsIdentity(transform) else {
            cropWorkbenchView.contentInset = .zero
            previousSkewInset = .zero
            return
        }
        
        let fr = imageContainer.frame
        let boundsW = cropWorkbenchView.bounds.width
        let boundsH = cropWorkbenchView.bounds.height
        let halfW = boundsW / 2
        let halfH = boundsH / 2
        let cropCorners = [
            CGPoint(x: -halfW, y: -halfH),
            CGPoint(x:  halfW, y: -halfH),
            CGPoint(x:  halfW, y:  halfH),
            CGPoint(x: -halfW, y:  halfH)
        ]
        
        // Use the CENTER of the image as the anchor, consistent with
        // computeSkewProjectionInputs. This makes insets independent of the
        // current pan position, preventing abrupt inset redistribution when
        // the perspective axis changes.
        let centerOffset = CGPoint(
            x: fr.midX - boundsW / 2,
            y: fr.midY - boundsH / 2
        )
        
        func isValidShift(_ shiftX: CGFloat, _ shiftY: CGFloat) -> Bool {
            let testAnchor = CGPoint(
                x: centerOffset.x + shiftX + boundsW / 2,
                y: centerOffset.y + shiftY + boundsH / 2
            )
            let testCorners = [
                CGPoint(x: fr.minX - testAnchor.x, y: fr.minY - testAnchor.y),
                CGPoint(x: fr.maxX - testAnchor.x, y: fr.minY - testAnchor.y),
                CGPoint(x: fr.maxX - testAnchor.x, y: fr.maxY - testAnchor.y),
                CGPoint(x: fr.minX - testAnchor.x, y: fr.maxY - testAnchor.y)
            ]
            let proj = testCorners.map {
                PerspectiveTransformHelper.projectDisplacement($0, through: transform)
            }
            return PerspectiveTransformHelper.allPointsInsideConvexPolygon(cropCorners, polygon: proj)
        }
        
        // Binary-search for the max valid distance along a given direction.
        func maxShift(dirX: CGFloat, dirY: CGFloat) -> CGFloat {
            let maxDist = max(boundsW, boundsH)
            var lo: CGFloat = 0
            var hi: CGFloat = maxDist
            for _ in 0..<16 {
                let mid = (lo + hi) / 2
                if isValidShift(dirX * mid, dirY * mid) {
                    lo = mid
                } else {
                    hi = mid
                }
            }
            return lo
        }

        let newInset: UIEdgeInsets

        if isValidShift(0, 0) {
            // First, get single-axis max shifts as upper bounds.
            let axisTop    = maxShift(dirX: 0, dirY: -1)
            let axisLeft   = maxShift(dirX: -1, dirY: 0)
            let axisBottom = maxShift(dirX: 0, dirY: 1)
            let axisRight  = maxShift(dirX: 1, dirY: 0)

            // Search along each diagonal to find the farthest valid corner.
            // Each diagonal is parameterised by t in [0, 1], scaling the
            // axis-based corner position.  This guarantees every corner of
            // the resulting inset rectangle is itself a valid shift.
            func diagonalMax(sx: CGFloat, sy: CGFloat) -> CGFloat {
                if isValidShift(sx, sy) { return 1.0 }
                var lo: CGFloat = 0
                var hi: CGFloat = 1.0
                for _ in 0..<14 {
                    let mid = (lo + hi) / 2
                    if isValidShift(sx * mid, sy * mid) {
                        lo = mid
                    } else {
                        hi = mid
                    }
                }
                return lo
            }

            let topLeftT     = diagonalMax(sx: -axisLeft,  sy: -axisTop)
            let topRightT    = diagonalMax(sx:  axisRight, sy: -axisTop)
            let bottomRightT = diagonalMax(sx:  axisRight, sy:  axisBottom)
            let bottomLeftT  = diagonalMax(sx: -axisLeft,  sy:  axisBottom)

            // Each inset is constrained by its two adjacent diagonals.
            let top    = axisTop    * min(topLeftT, topRightT)
            let left   = axisLeft   * min(topLeftT, bottomLeftT)
            let bottom = axisBottom * min(bottomRightT, bottomLeftT)
            let right  = axisRight  * min(topRightT, bottomRightT)

            newInset = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
            previousSkewInset = newInset
        } else {
            // Center-based test fails transiently at certain combined angles
            // (the compensating scale hasn't caught up due to rate-limiting).
            // Keep the previous insets to avoid collapsing to zero or
            // redistributing asymmetrically, which would cause a visible pan.
            newInset = previousSkewInset
        }
        
        // Pre-clamp contentOffset to fit within the new inset bounds BEFORE
        // setting the inset. This prevents UIScrollView from auto-clamping
        // (which causes a visible snap).
        let curOffset = cropWorkbenchView.contentOffset
        let maxOffsetX = cropWorkbenchView.contentSize.width - boundsW + newInset.right
        let maxOffsetY = cropWorkbenchView.contentSize.height - boundsH + newInset.bottom
        let clampedX = max(-newInset.left, min(maxOffsetX, curOffset.x))
        let clampedY = max(-newInset.top, min(maxOffsetY, curOffset.y))
        
        if clampedX != curOffset.x || clampedY != curOffset.y {
            cropWorkbenchView.contentOffset = CGPoint(x: clampedX, y: clampedY)
        }
        
        cropWorkbenchView.contentInset = newInset
    }
    
    /// Returns a valid contentOffset if the current one is outside the projected
    /// image quad, or nil if the current offset is already valid.
    private func computeValidContentOffset() -> CGPoint? {
        let transform = cropWorkbenchView.layer.sublayerTransform
        guard !CATransform3DIsIdentity(transform) else { return nil }
        
        let fr = imageContainer.frame
        let anchor = CGPoint(
            x: cropWorkbenchView.contentOffset.x + cropWorkbenchView.bounds.width / 2,
            y: cropWorkbenchView.contentOffset.y + cropWorkbenchView.bounds.height / 2
        )
        let halfW = cropWorkbenchView.bounds.width / 2
        let halfH = cropWorkbenchView.bounds.height / 2
        let cropCorners = [
            CGPoint(x: -halfW, y: -halfH),
            CGPoint(x:  halfW, y: -halfH),
            CGPoint(x:  halfW, y:  halfH),
            CGPoint(x: -halfW, y:  halfH)
        ]
        let imgCorners = [
            CGPoint(x: fr.minX - anchor.x, y: fr.minY - anchor.y),
            CGPoint(x: fr.maxX - anchor.x, y: fr.minY - anchor.y),
            CGPoint(x: fr.maxX - anchor.x, y: fr.maxY - anchor.y),
            CGPoint(x: fr.minX - anchor.x, y: fr.maxY - anchor.y)
        ]
        let proj = imgCorners.map {
            PerspectiveTransformHelper.projectDisplacement($0, through: transform)
        }
        
        if PerspectiveTransformHelper.allPointsInsideConvexPolygon(cropCorners, polygon: proj) {
            return nil  // Already valid
        }
        
        // Binary-search for the maximum fraction of offset-from-center that's valid
        let defaultOffset = CGPoint(
            x: fr.midX - halfW,
            y: fr.midY - halfH
        )
        let curOffset = cropWorkbenchView.contentOffset
        let dx = curOffset.x - defaultOffset.x
        let dy = curOffset.y - defaultOffset.y
        
        var lo: CGFloat = 0
        var hi: CGFloat = 1
        for _ in 0..<20 {
            let mid = (lo + hi) / 2
            let testOffset = CGPoint(x: defaultOffset.x + dx * mid,
                                     y: defaultOffset.y + dy * mid)
            let testAnchor = CGPoint(
                x: testOffset.x + halfW,
                y: testOffset.y + halfH
            )
            let testImgCorners = [
                CGPoint(x: fr.minX - testAnchor.x, y: fr.minY - testAnchor.y),
                CGPoint(x: fr.maxX - testAnchor.x, y: fr.minY - testAnchor.y),
                CGPoint(x: fr.maxX - testAnchor.x, y: fr.maxY - testAnchor.y),
                CGPoint(x: fr.minX - testAnchor.x, y: fr.maxY - testAnchor.y)
            ]
            let testProj = testImgCorners.map {
                PerspectiveTransformHelper.projectDisplacement($0, through: transform)
            }
            if PerspectiveTransformHelper.allPointsInsideConvexPolygon(cropCorners, polygon: testProj) {
                lo = mid
            } else {
                hi = mid
            }
        }
        
        return CGPoint(x: defaultOffset.x + dx * lo,
                        y: defaultOffset.y + dy * lo)
    }
    
    /// After the user finishes dragging, verify that the crop box still lies
    /// inside the projected (skewed) image quad. If it doesn't, animate the
    /// contentOffset back to the nearest valid position.
    ///
    /// Uses two strategies in order:
    /// 1. Clamp to the current contentInset bounds (cheap, no projection).
    /// 2. If still invalid, fall back to the projection-based binary search
    ///    toward center.
    func clampContentOffsetForSkewIfNeeded() {
        let hDeg = effectiveHorizontalSkewDegrees
        let vDeg = effectiveVerticalSkewDegrees
        guard hDeg != 0 || vDeg != 0 else { return }

        let inset = cropWorkbenchView.contentInset
        let boundsW = cropWorkbenchView.bounds.width
        let boundsH = cropWorkbenchView.bounds.height
        let curOffset = cropWorkbenchView.contentOffset
        let maxOffsetX = cropWorkbenchView.contentSize.width - boundsW + inset.right
        let maxOffsetY = cropWorkbenchView.contentSize.height - boundsH + inset.bottom
        let clampedX = max(-inset.left, min(maxOffsetX, curOffset.x))
        let clampedY = max(-inset.top, min(maxOffsetY, curOffset.y))
        let insetClamped = CGPoint(x: clampedX, y: clampedY)

        if insetClamped != curOffset {
            // Inset-based clamp is sufficient in most cases.
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
                self.cropWorkbenchView.contentOffset = insetClamped
            }
            return
        }

        // Inset-based clamp didn't move the offset, but the projection test
        // may still fail (e.g. after a zoom changed the geometry). Fall back
        // to the projection-based search toward center.
        guard let validOffset = computeValidContentOffset() else { return }

        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            self.cropWorkbenchView.contentOffset = validOffset
        }
    }
    
    /// Synchronizes the SlideDial's internal stored angles and button values
    /// with the CropView's viewModel skew degrees (e.g. after a 90° rotation swap).
    private func syncSlideDialSkewValues() {
        guard let slideDial = rotationControlView as? SlideDial else { return }
        slideDial.syncSkewValues(
            horizontal: viewModel.horizontalSkewDegrees,
            vertical: viewModel.verticalSkewDegrees
        )
    }
    
    private func computeSkewProjectionInputs(safetyInset: CGFloat) -> ([CGPoint], [CGPoint], CGPoint, CGPoint) {
        // Use the CENTER of the image container as the anchor, NOT the current
        // contentOffset. The sublayerTransform is applied uniformly to the
        // whole layer, so the compensating scale should not depend on where
        // the user has scrolled. Using contentOffset as anchor caused the
        // scale to change when switching skew axes after panning.
        let fr = imageContainer.frame
        let anchor = CGPoint(x: fr.midX, y: fr.midY)

        // Image container corners as displacements from the anchor (CW: TL, TR, BR, BL)
        let imageCornerDisplacements = [
            CGPoint(x: fr.minX - anchor.x, y: fr.minY - anchor.y),
            CGPoint(x: fr.maxX - anchor.x, y: fr.minY - anchor.y),
            CGPoint(x: fr.maxX - anchor.x, y: fr.maxY - anchor.y),
            CGPoint(x: fr.minX - anchor.x, y: fr.maxY - anchor.y)
        ]

        // Visible crop rect centered at the same anchor.
        // Since the scale must cover the crop area regardless of pan position,
        // we use the centered (default) view position.
        let boundsW = cropWorkbenchView.bounds.width
        let boundsH = cropWorkbenchView.bounds.height
        let cropBoxRectInContent = CGRect(
            x: anchor.x - boundsW / 2,
            y: anchor.y - boundsH / 2,
            width: boundsW,
            height: boundsH
        )
        let safetyRect = cropBoxRectInContent.insetBy(dx: -safetyInset, dy: -safetyInset)
        let visibleCornerDisplacements = [
            CGPoint(x: safetyRect.minX - anchor.x, y: safetyRect.minY - anchor.y),
            CGPoint(x: safetyRect.maxX - anchor.x, y: safetyRect.minY - anchor.y),
            CGPoint(x: safetyRect.maxX - anchor.x, y: safetyRect.maxY - anchor.y),
            CGPoint(x: safetyRect.minX - anchor.x, y: safetyRect.maxY - anchor.y)
        ]

        let visibleCenter = CGPoint(
            x: (safetyRect.minX + safetyRect.maxX) / 2 - anchor.x,
            y: (safetyRect.minY + safetyRect.maxY) / 2 - anchor.y
        )

        let visibleTopLeft = CGPoint(x: safetyRect.minX - anchor.x, y: safetyRect.minY - anchor.y)
        return (imageCornerDisplacements, visibleCornerDisplacements, visibleCenter, visibleTopLeft)
    }
    
    /// Sets the horizontal skew degrees and refreshes the view
    func setHorizontalSkew(degrees: CGFloat) {
        let clamped = max(-PerspectiveTransformHelper.maxSkewDegrees,
                          min(PerspectiveTransformHelper.maxSkewDegrees, degrees))
        viewModel.horizontalSkewDegrees = clamped
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        checkImageStatusChanged()
    }
    
    /// Sets the vertical skew degrees and refreshes the view
    func setVerticalSkew(degrees: CGFloat) {
        let clamped = max(-PerspectiveTransformHelper.maxSkewDegrees,
                          min(PerspectiveTransformHelper.maxSkewDegrees, degrees))
        viewModel.verticalSkewDegrees = clamped
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        checkImageStatusChanged()
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
            rotationControlViewHeight = slideDialHandlesTypeSelection
                ? max(cropViewConfig.rotationControlViewHeight, 120)
                : cropViewConfig.rotationControlViewHeight
        }
        
        // Add space for rotation type selector if enabled
        // (Only needed for the external text-based selector; SlideDial withTypeSelector
        // embeds its buttons within the rotationControlViewHeight area)
        var rotationTypeSelectorHeight: CGFloat = 0
        if cropViewConfig.enablePerspectiveCorrection && !slideDialHandlesTypeSelection {
            rotationTypeSelectorHeight = 32
        }
        
        if Orientation.treatAsPortrait {
            contentRect.origin.x = rect.origin.x + cropViewPadding
            contentRect.origin.y = rect.origin.y + cropViewPadding
            
            contentRect.size.width = rect.width - 2 * cropViewPadding
            contentRect.size.height = rect.height - 2 * cropViewPadding - rotationControlViewHeight - rotationTypeSelectorHeight
        } else if Orientation.isLandscape {
            contentRect.size.width = rect.width - 2 * cropViewPadding - rotationControlViewHeight - rotationTypeSelectorHeight
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
        // Temporarily remove the 3D perspective skew so that coordinate
        // conversions between the crop overlay and the image container
        // are purely 2D-affine.  The sublayerTransform includes a
        // compensating scale that distorts convert(_:to:) results,
        // causing progressive zoom drift on every device rotation.
        let savedSublayerTransform = cropWorkbenchView.layer.sublayerTransform
        let hasSkew = viewModel.horizontalSkewDegrees != 0 || viewModel.verticalSkewDegrees != 0
        if hasSkew {
            cropWorkbenchView.layer.sublayerTransform = CATransform3DIdentity
        }
        
        viewModel.cropLeftTopOnImage = getImageLeftTopAnchorPoint()
        viewModel.cropRightBottomOnImage = getImageRightBottomAnchorPoint()
        
        if hasSkew {
            cropWorkbenchView.layer.sublayerTransform = savedSublayerTransform
        }
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
        let hasSkew = viewModel.horizontalSkewDegrees != 0 || viewModel.verticalSkewDegrees != 0
        
        if hasSkew {
            // When skew is active, the sublayerTransform visually enlarges the
            // image beyond its content coordinate bounds by the compensating
            // scale factor. Use that factor as tolerance so the containment
            // check still catches genuinely out-of-bounds situations while
            // ignoring the visual enlargement.
            let scale = previousSkewScale
            let cropFrame = cropAuxiliaryIndicatorView.frame
            let toleranceX = cropFrame.width * (scale - 1) / 2
            let toleranceY = cropFrame.height * (scale - 1) / 2
            let tolerance = max(toleranceX, toleranceY, 0.5)
            
            if !imageContainer.contains(rect: cropFrame, fromView: self, tolerance: tolerance) {
                cropWorkbenchView.zoomScaleToBound(animated: true)
                updateContentInsetForSkew()
            }
        } else {
            if !imageContainer.contains(rect: cropAuxiliaryIndicatorView.frame, fromView: self, tolerance: 0.25) {
                cropWorkbenchView.zoomScaleToBound(animated: true)
            }
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
            transformation: makeTransformation(),
            horizontalSkewDegrees: viewModel.horizontalSkewDegrees,
            verticalSkewDegrees: viewModel.verticalSkewDegrees
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
            verticallyFlipped: viewModel.verticallyFlip,
            horizontalSkewDegrees: viewModel.horizontalSkewDegrees,
            verticalSkewDegrees: viewModel.verticalSkewDegrees
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
            // For SlideDial: update the ruler when showing straighten,
            // or silently sync the stored straighten value when on a skew tab.
            // Skew values are kept unchanged on the dial after flip (the
            // effective negation is applied at transform time).
            if let slideDial = rotationControlView as? SlideDial {
                if currentRotationAdjustmentType == .straighten {
                    slideDial.updateRotationValue(by: Angle(degrees: viewModel.degrees))
                } else {
                    slideDial.syncStraightenValue(viewModel.degrees)
                }
            } else {
                rotationControlView?.updateRotationValue(by: Angle(degrees: viewModel.degrees))
            }
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
        
        // Temporarily zero out the skew so that all geometry calculations
        // (rotateCropWorkbenchView, adjustWorkbenchView, zoomScaleToBound,
        // convert(_:to:), adjustUIForNewCrop) operate in pure 2D space.
        // The sublayerTransform's compensating scale distorts every
        // coordinate conversion that crosses the scroll-view layer boundary,
        // causing progressive zoom drift on repeated device rotations.
        let savedHSkew = viewModel.horizontalSkewDegrees
        let savedVSkew = viewModel.verticalSkewDegrees
        let hasSkew = savedHSkew != 0 || savedVSkew != 0
        if hasSkew {
            viewModel.horizontalSkewDegrees = 0
            viewModel.verticalSkewDegrees = 0
        }
        
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
                guard let self = self else { return }
                // Restore skew after all geometry is settled.
                if hasSkew {
                    self.viewModel.horizontalSkewDegrees = savedHSkew
                    self.viewModel.verticalSkewDegrees = savedVSkew
                    self.previousSkewScale = 1.0
                    self.previousSkewInset = .zero
                    self.applySkewTransformIfNeeded()
                    self.updateContentInsetForSkew()
                }
                self.viewModel.setBetweenOperationStatus()
            }
        } else {
            // No anchor points to restore — just re-apply skew.
            if hasSkew {
                viewModel.horizontalSkewDegrees = savedHSkew
                viewModel.verticalSkewDegrees = savedVSkew
                previousSkewScale = 1.0
                previousSkewInset = .zero
                applySkewTransformIfNeeded()
                updateContentInsetForSkew()
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
        
        // Save skew state and reset to identity before rotation
        let savedHSkew = viewModel.horizontalSkewDegrees
        let savedVSkew = viewModel.verticalSkewDegrees
        let hadSkew = savedHSkew != 0 || savedVSkew != 0
        
        // Temporarily zero out skew so the rotation animation and geometry
        // calculations work purely in 2D, without 3D perspective interference.
        if hadSkew {
            viewModel.horizontalSkewDegrees = 0
            viewModel.verticalSkewDegrees = 0
            cropWorkbenchView.layer.sublayerTransform = CATransform3DIdentity
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
            
            // Restore skew inside the animation block so it transitions smoothly
            // instead of jumping back abruptly in the completion handler.
            if hadSkew {
                viewModel.horizontalSkewDegrees = savedHSkew
                viewModel.verticalSkewDegrees = savedVSkew
                previousSkewScale = 1.0
                previousSkewInset = .zero
                applySkewTransformIfNeeded()
                updateContentInsetForSkew()
            }
        }
        
        func handleRotateCompletion() {
            cropWorkbenchView.updateMinZoomScale()
            viewModel.rotateBy90(withRotateType: newRotateType)
            
            // Ensure skew values are set (they were restored during animation,
            // but rotateBy90 above may affect geometry, so re-apply).
            viewModel.horizontalSkewDegrees = savedHSkew
            viewModel.verticalSkewDegrees = savedVSkew
            
            if viewModel.horizontalSkewDegrees != 0 || viewModel.verticalSkewDegrees != 0 {
                previousSkewScale = 1.0
                previousSkewInset = .zero
                applySkewTransformIfNeeded()
                updateContentInsetForSkew()
            }
            
            // Keep the SlideDial's stored angles in sync.
            syncSlideDialSkewValues()
            
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
        viewModel.horizontalSkewDegrees = cropState.horizontalSkewDegrees
        viewModel.verticalSkewDegrees = cropState.verticalSkewDegrees
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
        
        // Restore skew transforms
        previousSkewScale = 1.0
        previousSkewInset = .zero
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        syncSlideDialSkewValues()
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
        
        // Restore skew values
        viewModel.horizontalSkewDegrees = transformation.horizontalSkewDegrees
        viewModel.verticalSkewDegrees = transformation.verticalSkewDegrees
        previousSkewScale = 1.0
        previousSkewInset = .zero
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        
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
            syncSlideDialSkewValues()
            completion(transformInfo)
        case .presetNormalizedInfo(let normalizedInfo):
            let transformInfo = getTransformInfo(byNormalizedInfo: normalizedInfo)
            transform(byTransformInfo: transformInfo)
            cropWorkbenchView.frame = transformInfo.maskFrame
            syncSlideDialSkewValues()
            completion(transformInfo)
        case .none:
            break
        }
    }
    
    func horizontallyFlip() {
        viewModel.horizontallyFlip.toggle()
        flip(isHorizontal: true)
        previousSkewScale = 1.0
        previousSkewInset = .zero
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        checkImageStatusChanged()
    }
    
    func verticallyFlip() {
        viewModel.verticallyFlip.toggle()
        flip(isHorizontal: false)
        previousSkewScale = 1.0
        previousSkewInset = .zero
        applySkewTransformIfNeeded()
        updateContentInsetForSkew()
        checkImageStatusChanged()
    }
    
    func reset() {
        flipOddTimes = false
        aspectRatioLockEnabled = forceFixedRatio
        viewModel.reset(forceFixedRatio: forceFixedRatio)
        
        // Reset skew state
        currentRotationAdjustmentType = .straighten
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
            cropRegion: cropRegion,
            horizontalSkewDegrees: viewModel.horizontalSkewDegrees,
            verticalSkewDegrees: viewModel.verticalSkewDegrees,
            skewSublayerTransform: cropWorkbenchView.layer.sublayerTransform,
            scrollContentOffset: cropWorkbenchView.contentOffset,
            scrollBoundsSize: cropWorkbenchView.bounds.size,
            imageContainerFrame: imageContainer.frame
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

// MARK: - RotationTypeSelectorDelegate
extension CropView: RotationTypeSelectorDelegate {
    func rotationTypeSelector(_ selector: RotationTypeSelector,
                              didSelectType type: RotationAdjustmentType) {
        // Save the current dial value for the previous mode before switching
        let previousType = currentRotationAdjustmentType
        if let currentDialValue = rotationControlView?.getTotalRotationValue() {
            switch previousType {
            case .straighten:
                viewModel.degrees = currentDialValue
            case .horizontalSkew:
                viewModel.horizontalSkewDegrees = currentDialValue
            case .verticalSkew:
                viewModel.verticalSkewDegrees = currentDialValue
            }
        }
        
        currentRotationAdjustmentType = type
        
        // Reset the dial and set it to the stored value for the new mode
        rotationControlView?.reset()
        switch type {
        case .straighten:
            rotationControlView?.updateRotationValue(by: Angle(degrees: viewModel.degrees))
        case .horizontalSkew:
            rotationControlView?.updateRotationValue(by: Angle(degrees: viewModel.horizontalSkewDegrees))
        case .verticalSkew:
            rotationControlView?.updateRotationValue(by: Angle(degrees: viewModel.verticalSkewDegrees))
        }
    }
    
    /// Sets up the rotation type selector below the rotation dial.
    /// When SlideDial is in withTypeSelector mode, the selector is built-in, so skip the external one.
    func setupRotationTypeSelector() {
        guard cropViewConfig.enablePerspectiveCorrection else { return }
        
        // If SlideDial handles type selection internally, hide the old external selector
        if let slideDial = rotationControlView as? SlideDial,
           case .withTypeSelector = slideDial.config.mode {
            rotationTypeSelector.isHidden = true
            rotationTypeSelector.removeFromSuperview()
            return
        }
        
        if rotationTypeSelector.superview == nil {
            addSubview(rotationTypeSelector)
        }
        
        rotationTypeSelector.isUserInteractionEnabled = true
        rotationTypeSelector.isHidden = false
        layoutRotationTypeSelector()
        rotationTypeSelector.bringSelfToFront()
    }
    
    func layoutRotationTypeSelector() {
        guard cropViewConfig.enablePerspectiveCorrection,
              rotationTypeSelector.superview != nil else { return }
        
        let selectorWidth: CGFloat = 220
        let selectorHeight: CGFloat = 28
        
        if Orientation.treatAsPortrait {
            if let rotationView = rotationControlView, rotationView.isAttachedToCropView {
                rotationTypeSelector.frame = CGRect(
                    x: rotationView.frame.midX - selectorWidth / 2,
                    y: rotationView.frame.maxY + 4,
                    width: selectorWidth,
                    height: selectorHeight
                )
            } else {
                rotationTypeSelector.frame = CGRect(
                    x: cropAuxiliaryIndicatorView.frame.midX - selectorWidth / 2,
                    y: cropAuxiliaryIndicatorView.frame.maxY + cropViewConfig.rotationControlViewHeight + 4,
                    width: selectorWidth,
                    height: selectorHeight
                )
            }
        } else {
            // Landscape: position beside the crop area
            rotationTypeSelector.frame = CGRect(
                x: cropAuxiliaryIndicatorView.frame.midX - selectorWidth / 2,
                y: cropAuxiliaryIndicatorView.frame.maxY + cropViewConfig.rotationControlViewHeight + 4,
                width: selectorWidth,
                height: selectorHeight
            )
        }
    }
}
