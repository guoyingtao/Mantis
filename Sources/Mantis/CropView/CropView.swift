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
    func cropViewDidBecomeResettable(_ cropView: CropView)
    func cropViewDidBecomeUnResettable(_ cropView: CropView)
    func cropViewDidBeginResize(_ cropView: CropView)
    func cropViewDidEndResize(_ cropView: CropView)
}

class CropView: UIView {
    private let angleDashboardHeight: CGFloat = 60
    
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
    let cropOverlayView: CropOverlayViewProtocol
    let scrollView: CropScrollViewProtocol
    let cropMaskViewManager: CropMaskViewManagerProtocol
    
    var rotationDial: RotationDial?
    
    var manualZoomed = false
    var forceFixedRatio = false
    var checkForForceFixedRatioFlag = false
    let cropViewConfig: CropViewConfig
    
    lazy private var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(frame: .zero)
        activityIndicator.color = .white
        let indicatorSize: CGFloat = 100
        activityIndicator.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        
        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: indicatorSize).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: indicatorSize).isActive = true
        
        return activityIndicator
    }()
    
    deinit {
        print("CropView deinit.")
    }
    
    init(
        image: UIImage,
        cropViewConfig: CropViewConfig,
        viewModel: CropViewModelProtocol,
        cropOverlayView: CropOverlayViewProtocol,
        imageContainer: ImageContainerProtocol,
        cropScrollView: CropScrollViewProtocol,
        cropMaskViewManager: CropMaskViewManagerProtocol
    ) {
        self.image = image
        self.cropViewConfig = cropViewConfig
        self.viewModel = viewModel
        self.cropOverlayView = cropOverlayView
        self.imageContainer = imageContainer
        self.scrollView = cropScrollView
        self.cropMaskViewManager = cropMaskViewManager
        
        super.init(frame: .zero)
        
        viewModel.statusChanged = { [weak self] status in
            self?.render(by: status)
        }
        
        viewModel.cropBoxFrameChanged = { [weak self] cropBoxFrame in
            self?.handleCropBoxFrameChange(cropBoxFrame)
        }
        
        initalRender()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func handleCropBoxFrameChange(_ cropBoxFrame: CGRect) {
        cropOverlayView.frame = cropBoxFrame
        
        var cropRatio: CGFloat = 1.0
        if cropOverlayView.frame.height != 0 {
            cropRatio = self.cropOverlayView.frame.width / self.cropOverlayView.frame.height
        }
        
        cropMaskViewManager.adaptMaskTo(match: cropBoxFrame, cropRatio: cropRatio)
    }
    
    private func initalRender() {
        setupScrollView()
        setGridOverlayView()
        checkImageStatusChanged()
    }
    
    private func render(by viewStatus: CropViewStatus) {
        cropOverlayView.isHidden = false
        
        switch viewStatus {
        case .initial:
            initalRender()
        case .rotating(let angle):
            viewModel.degrees = angle.degrees
            rotateScrollView()
        case .degree90Rotating:
            cropMaskViewManager.showVisualEffectBackground()
            cropOverlayView.isHidden = true
            rotationDial?.isHidden = true
        case .touchImage:
            cropMaskViewManager.showDimmingBackground()
            cropOverlayView.gridLineNumberType = .crop
            cropOverlayView.setGrid(hidden: false, animated: true)
        case .touchCropboxHandle(let tappedEdge):
            cropOverlayView.handleEdgeTouched(with: tappedEdge)
            rotationDial?.isHidden = true
            cropMaskViewManager.showDimmingBackground()
        case .touchRotationBoard:
            cropOverlayView.gridLineNumberType = .rotate
            cropOverlayView.setGrid(hidden: false, animated: true)
            cropMaskViewManager.showDimmingBackground()
        case .betweenOperation:
            cropOverlayView.handleEdgeUntouched()
            rotationDial?.isHidden = false
            adaptAngleDashboardToCropBox()
            cropMaskViewManager.showVisualEffectBackground()
            checkImageStatusChanged()
        }
    }
    
    private func isTheSamePoint(point1: CGPoint, point2: CGPoint) -> Bool {
        let tolerance = CGFloat.ulpOfOne * 10
        if abs(point1.x - point2.x) > tolerance { return false }
        if abs(point1.y - point2.y) > tolerance { return false }
        
        return true
    }
    
    private func imageStatusChanged() -> Bool {
        if viewModel.getTotalRadians() != 0 { return true }
        
        if forceFixedRatio {
            if checkForForceFixedRatioFlag {
                checkForForceFixedRatioFlag = false
                return scrollView.zoomScale != 1
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
    
    func resetComponents() {
        cropMaskViewManager.removeMaskViews()
        cropMaskViewManager.setup(in: self, cropRatio: CGFloat(getImageRatioH()))
        viewModel.resetCropFrame(by: getInitialCropBoxRect())
        scrollView.resetImageContent(by: viewModel.cropBoxFrame)
        cropOverlayView.superview?.bringSubviewToFront(cropOverlayView)
        
        setupAngleDashboard()
        
        if aspectRatioLockEnabled {
            setFixedRatioCropBox()
        }
    }
    
    private func setupScrollView() {
        scrollView.touchesBegan = { [weak self] in
            self?.viewModel.setTouchImageStatus()
        }
        
        scrollView.touchesEnded = { [weak self] in
            self?.viewModel.setBetweenOperationStatus()
        }
        
        scrollView.delegate = self
        addSubview(scrollView)
        
        if cropViewConfig.minimumZoomScale > 1 {
            scrollView.zoomScale = cropViewConfig.minimumZoomScale
        }
    }
    
    private func setGridOverlayView() {
        cropOverlayView.isUserInteractionEnabled = false
        cropOverlayView.gridHidden = true
        addSubview(cropOverlayView)
    }
    
    private func setupAngleDashboard() {
        guard cropViewConfig.showRotationDial else {
            return
        }
        
        if rotationDial != nil {
            rotationDial?.removeFromSuperview()
        }
        
        let boardLength = min(bounds.width, bounds.height) * 0.6
        let rotationDial = RotationDial(frame: CGRect(x: 0,
                                                      y: 0,
                                                      width: boardLength,
                                                      height: angleDashboardHeight),
                                        dialConfig: cropViewConfig.dialConfig)
        self.rotationDial = rotationDial
        rotationDial.isUserInteractionEnabled = true
        addSubview(rotationDial)
        
        rotationDial.setRotationCenter(by: cropOverlayView.center, of: self)
        
        rotationDial.didRotate = { [unowned self] angle in
            self.viewModel.setRotatingStatus(by: angle)
        }
        
        rotationDial.didFinishedRotate = { [unowned self] in
            self.viewModel.setBetweenOperationStatus()
        }
        
        rotationDial.rotateDialPlate(by: CGAngle(radians: viewModel.radians))
        adaptAngleDashboardToCropBox()
    }
    
    private func adaptAngleDashboardToCropBox() {
        guard let rotationDial = rotationDial else { return }
        
        if Orientation.isPortrait {
            rotationDial.transform = CGAffineTransform(rotationAngle: 0)
            rotationDial.frame.origin.x = cropOverlayView.frame.origin.x +  (cropOverlayView.frame.width - rotationDial.frame.width) / 2
            rotationDial.frame.origin.y = cropOverlayView.frame.maxY
        } else if Orientation.isLandscapeLeft {
            rotationDial.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            rotationDial.frame.origin.x = cropOverlayView.frame.maxX
            rotationDial.frame.origin.y = cropOverlayView.frame.origin.y + (cropOverlayView.frame.height - rotationDial.frame.height) / 2
        } else if Orientation.isLandscapeRight {
            rotationDial.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            rotationDial.frame.origin.x = cropOverlayView.frame.minX - rotationDial.frame.width
            rotationDial.frame.origin.y = cropOverlayView.frame.origin.y + (cropOverlayView.frame.height - rotationDial.frame.height) / 2
        }
    }
    
    func updateCropBoxFrame(with point: CGPoint) {
        let contentBounds = getContentBounds()
        
        guard contentBounds.contains(point) else {
            return
        }
        
        let imageFrame = CGRect(x: scrollView.frame.origin.x - scrollView.contentOffset.x,
                                y: scrollView.frame.origin.y - scrollView.contentOffset.y,
                                width: imageContainer.frame.width,
                                height: imageContainer.frame.height)
        
        guard imageFrame.contains(point) else {
            return
        }
        
        let cropViewMinimumBoxSize = cropViewConfig.minimumCropBoxSize
        let newCropBoxFrame = viewModel.getNewCropBoxFrame(with: point, and: contentBounds, aspectRatioLockEnabled: aspectRatioLockEnabled)
        
        guard newCropBoxFrame.width >= cropViewMinimumBoxSize
                && newCropBoxFrame.minX >= contentBounds.minX
                && newCropBoxFrame.maxX <= contentBounds.maxX
                && newCropBoxFrame.height >= cropViewMinimumBoxSize
                && newCropBoxFrame.minY >= contentBounds.minY
                && newCropBoxFrame.maxY <= contentBounds.maxY else {
            return
        }
        
        if imageContainer.contains(rect: newCropBoxFrame, fromView: self, tolerance: 0.5) {
            viewModel.cropBoxFrame = newCropBoxFrame
        } else {
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
    private func rotateScrollView() {
        let totalRadians = viewModel.getTotalRadians()
        scrollView.transform = CGAffineTransform(rotationAngle: totalRadians)
        
        if viewModel.horizontallyFlip {
            if viewModel.rotationType.isRotateByMultiple180 {
                scrollView.transform = scrollView.transform.scaledBy(x: -1, y: 1)
            } else {
                scrollView.transform = scrollView.transform.scaledBy(x: 1, y: -1)
            }
        }
        
        if viewModel.verticallyFlip {
            if viewModel.rotationType.isRotateByMultiple180 {
                scrollView.transform = scrollView.transform.scaledBy(x: 1, y: -1)
            } else {
                scrollView.transform = scrollView.transform.scaledBy(x: -1, y: 1)
            }
        }
        
        updatePosition(by: totalRadians)
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
    
    func getContentBounds() -> CGRect {
        let cropViewPadding = cropViewConfig.padding
        
        let rect = self.bounds
        var contentRect = CGRect.zero
        
        if Orientation.isPortrait {
            contentRect.origin.x = rect.origin.x + cropViewPadding
            contentRect.origin.y = rect.origin.y + cropViewPadding
            
            contentRect.size.width = rect.width - 2 * cropViewPadding
            contentRect.size.height = rect.height - 2 * cropViewPadding - angleDashboardHeight
        } else if Orientation.isLandscape {
            contentRect.size.width = rect.width - 2 * cropViewPadding - angleDashboardHeight
            contentRect.size.height = rect.height - 2 * cropViewPadding
            
            contentRect.origin.y = rect.origin.y + cropViewPadding
            if Orientation.isLandscapeLeft {
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
        
        let leftTopPoint = cropOverlayView.convert(CGPoint(x: 0, y: 0), to: imageContainer)
        let point = CGPoint(x: leftTopPoint.x / imageContainer.bounds.width, y: leftTopPoint.y / imageContainer.bounds.height)
        return point
    }
    
    fileprivate func getImageRightBottomAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.cropRightBottomOnImage
        }
        
        let rightBottomPoint = cropOverlayView.convert(CGPoint(x: cropOverlayView.bounds.width, y: cropOverlayView.bounds.height), to: imageContainer)
        let point = CGPoint(x: rightBottomPoint.x / imageContainer.bounds.width, y: rightBottomPoint.y / imageContainer.bounds.height)
        return point
    }
    
    fileprivate func saveAnchorPoints() {
        viewModel.cropLeftTopOnImage = getImageLeftTopAnchorPoint()
        viewModel.cropRightBottomOnImage = getImageRightBottomAnchorPoint()
    }
    
    func adjustUIForNewCrop(contentRect: CGRect,
                            animation: Bool = true,
                            zoom: Bool = true,
                            completion: @escaping () -> Void) {
        let scaleX: CGFloat
        let scaleY: CGFloat
        
        scaleX = contentRect.width / viewModel.cropBoxFrame.size.width
        scaleY = contentRect.height / viewModel.cropBoxFrame.size.height
        
        let scale = min(scaleX, scaleY)
        
        let newCropBounds = CGRect(x: 0, y: 0, width: viewModel.cropBoxFrame.width * scale, height: viewModel.cropBoxFrame.height * scale)
        
        let radians = viewModel.getTotalRadians()
        
        // calculate the new bounds of scroll view
        let newBoundWidth = abs(cos(radians)) * newCropBounds.size.width + abs(sin(radians)) * newCropBounds.size.height
        let newBoundHeight = abs(sin(radians)) * newCropBounds.size.width + abs(cos(radians)) * newCropBounds.size.height
        
        // calculate the zoom area of scroll view
        var scaleFrame = viewModel.cropBoxFrame
        
        let refContentWidth = abs(cos(radians)) * scrollView.contentSize.width + abs(sin(radians)) * scrollView.contentSize.height
        let refContentHeight = abs(sin(radians)) * scrollView.contentSize.width + abs(cos(radians)) * scrollView.contentSize.height
        
        if scaleFrame.width >= refContentWidth {
            scaleFrame.size.width = refContentWidth
        }
        if scaleFrame.height >= refContentHeight {
            scaleFrame.size.height = refContentHeight
        }
        
        let contentOffset = scrollView.contentOffset
        let contentOffsetCenter = CGPoint(x: (contentOffset.x + scrollView.bounds.width / 2),
                                          y: (contentOffset.y + scrollView.bounds.height / 2))
        
        scrollView.bounds = CGRect(x: 0, y: 0, width: newBoundWidth, height: newBoundHeight)
        
        let newContentOffset = CGPoint(x: (contentOffsetCenter.x - newBoundWidth / 2),
                                       y: (contentOffsetCenter.y - newBoundHeight / 2))
        scrollView.contentOffset = newContentOffset
        
        let newCropBoxFrame = GeometryHelper.getInscribeRect(fromOutsideRect: contentRect, andInsideRect: viewModel.cropBoxFrame)
        
        func updateUI(by newCropBoxFrame: CGRect, and scaleFrame: CGRect) {
            viewModel.cropBoxFrame = newCropBoxFrame
            
            if zoom {
                let zoomRect = convert(scaleFrame,
                                       to: scrollView.imageContainer)
                scrollView.zoom(to: zoomRect, animated: false)
            }
            scrollView.checkContentOffset()
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
        
        manualZoomed = true
    }
    
    func makeSureImageContainsCropOverlay() {
        if !imageContainer.contains(rect: cropOverlayView.frame, fromView: self, tolerance: 0.25) {
            scrollView.zoomScaleToBound(animated: true)
        }
    }
    
    fileprivate func updatePosition(by radians: CGFloat) {
        let width = abs(cos(radians)) * cropOverlayView.frame.width + abs(sin(radians)) * cropOverlayView.frame.height
        let height = abs(sin(radians)) * cropOverlayView.frame.width + abs(cos(radians)) * cropOverlayView.frame.height
        
        scrollView.updateLayout(byNewSize: CGSize(width: width, height: height))
        
        if !manualZoomed || scrollView.shouldScale() {
            scrollView.zoomScaleToBound(animated: false)
            manualZoomed = false
        } else {
            scrollView.updateMinZoomScale()
        }
        
        scrollView.checkContentOffset()
    }
    
    func updatePositionFor90Rotation(by radians: CGFloat) {
        func adjustScrollViewForNormalRatio(by radians: CGFloat) -> CGFloat {
            let width = abs(cos(radians)) * cropOverlayView.frame.width + abs(sin(radians)) * cropOverlayView.frame.height
            let height = abs(sin(radians)) * cropOverlayView.frame.width + abs(cos(radians)) * cropOverlayView.frame.height
            
            let newSize: CGSize
            if viewModel.rotationType.isRotateByMultiple180 {
                newSize = CGSize(width: width, height: height)
            } else {
                newSize = CGSize(width: height, height: width)
            }
            
            let scale = newSize.width / scrollView.bounds.width
            scrollView.updateLayout(byNewSize: newSize)
            return scale
        }
        
        let scale = adjustScrollViewForNormalRatio(by: radians)
        
        let newZoomScale = scrollView.zoomScale * scale
        scrollView.minimumZoomScale = newZoomScale
        scrollView.zoomScale = newZoomScale
        
        scrollView.checkContentOffset()
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
                self.activityIndicator.isHidden = true
                completion(maskedCropOutput)
            }
        }
    }
    
    func makeTransformation() -> Transformation {
        Transformation(
            offset: scrollView.contentOffset,
            rotation: getTotalRadians(),
            scale: scrollView.zoomScale,
            manualZoomed: manualZoomed,
            intialMaskFrame: getInitialCropBoxRect(),
            maskFrame: cropOverlayView.frame,
            scrollBounds: scrollView.bounds
        )
    }
    
    func addImageMask(to cropOutput: CropOutput) -> CropOutput {
        let (croppedImage, transformation, cropInfo) = cropOutput
        
        guard let croppedImage = croppedImage else {
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
            return CropOutput(croppedImage.clipPath(points,
                                                    borderWidth: cropViewConfig.cropBorderWidth,
                                                    borderColor: cropViewConfig.cropBorderColor),
                              transformation,
                              cropInfo)
        }
    }
    
    func getTotalRadians() -> CGFloat {
        return viewModel.getTotalRadians()
    }
    
    fileprivate func setRotation(byRadians radians: CGFloat) {
        scrollView.transform = CGAffineTransform(rotationAngle: radians)
        updatePosition(by: radians)
        rotationDial?.rotateDialPlate(to: CGAngle(radians: radians), animated: false)
    }
    
    func setFixedRatioCropBox(zoom: Bool = true, cropBox: CGRect? = nil) {
        let refCropBox = cropBox ?? getInitialCropBoxRect()
        viewModel.setCropBoxFrame(by: refCropBox, and: getImageRatioH())
        
        let contentRect = getContentBounds()
        adjustUIForNewCrop(contentRect: contentRect, animation: false, zoom: zoom) { [weak self] in
            guard let self = self else { return }
            if self.forceFixedRatio {
                self.checkForForceFixedRatioFlag = true
            }
            self.viewModel.setBetweenOperationStatus()
        }
        
        adaptAngleDashboardToCropBox()
        scrollView.updateMinZoomScale()
    }
    
    private func flip(isHorizontal: Bool = true, animated: Bool = true) {
        var scaleX: CGFloat = 1
        var scaleY: CGFloat = 1
        
        if isHorizontal {
            if viewModel.rotationType.isRotateByMultiple180 {
                scaleX = -scaleX
            } else {
                scaleY = -scaleY
            }
        } else {
            if viewModel.rotationType.isRotateByMultiple180 {
                scaleY = -scaleY
            } else {
                scaleX = -scaleX
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.5) {
                self.scrollView.transform = self.scrollView.transform.scaledBy(x: scaleX, y: scaleY)
            }
        } else {
            scrollView.transform = scrollView.transform.scaledBy(x: scaleX, y: scaleY)
        }
    }
}

extension CropView: CropViewProtocol {
    func initialSetup(delegate: CropViewDelegate, alwaysUsingOnePresetFixedRatio: Bool = false) {
        self.delegate = delegate
        setViewDefaultProperties()
        forceFixedRatio = alwaysUsingOnePresetFixedRatio
    }
    
    func getRatioType(byImageIsOriginalisHorizontal isHorizontal: Bool) -> RatioType {
        return viewModel.getRatioType(byImageIsOriginalHorizontal: isHorizontal)
    }
    
    func getImageRatioH() -> Double {
        if viewModel.rotationType.isRotateByMultiple180 {
            return Double(image.ratioH())
        } else {
            return Double(1/image.ratioH())
        }
    }
        
    func prepareForDeviceRotation() {
        viewModel.setDegree90RotatingStatus()
        saveAnchorPoints()
    }
    
    func handleDeviceRotated() {
        viewModel.resetCropFrame(by: getInitialCropBoxRect())
        
        scrollView.transform = CGAffineTransform(scaleX: 1, y: 1)
        scrollView.reset(by: viewModel.cropBoxFrame)
        
        setupAngleDashboard()
        rotateScrollView()
        
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
                self?.adaptAngleDashboardToCropBox()
                self?.viewModel.setBetweenOperationStatus()
            }
        }
    }
    
    func setFixedRatio(_ ratio: Double, zoom: Bool = true, alwaysUsingOnePresetFixedRatio: Bool = false) {
        aspectRatioLockEnabled = true
        
        if viewModel.aspectRatio != CGFloat(ratio) {
            viewModel.aspectRatio = CGFloat(ratio)
            
            if alwaysUsingOnePresetFixedRatio {
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
            var rect = cropOverlayView.frame
            rect.size.width = cropOverlayView.frame.height
            rect.size.height = cropOverlayView.frame.width

            let newRect = GeometryHelper.getInscribeRect(fromOutsideRect: getContentBounds(), andInsideRect: rect)
            viewModel.cropBoxFrame = newRect
            let rotateAngle = newRotateType == .clockwise ? CGFloat.pi / 2 : -CGFloat.pi / 2
            scrollView.transform = scrollView.transform.rotated(by: rotateAngle)
            updatePositionFor90Rotation(by: rotateAngle + viewModel.radians)
        }
        
        func handleRoteteCompletion() {
            scrollView.updateMinZoomScale()
            viewModel.rotateBy90(withRotateType: newRotateType)
            viewModel.setBetweenOperationStatus()
            completion()
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            handleRotateAnimation()
        }, completion: { _ in
            handleRoteteCompletion()
        })
    }
    
    func handleAlterCropper90Degree() {
        let ratio = Double(cropOverlayView.frame.height / cropOverlayView.frame.width)
        
        viewModel.aspectRatio = CGFloat(ratio)
        
        UIView.animate(withDuration: 0.5) {
            self.setFixedRatioCropBox()
        }
    }
    
    func handlePresetFixedRatio(_ ratio: Double, transformation: Transformation) {
        aspectRatioLockEnabled = true
        
        if ratio == 0 {
            viewModel.aspectRatio = transformation.maskFrame.width / transformation.maskFrame.height
        } else {
            viewModel.aspectRatio = CGFloat(ratio)
            setFixedRatioCropBox(zoom: false, cropBox: viewModel.cropBoxFrame)
        }
    }
    
    func transform(byTransformInfo transformation: Transformation, rotateDial: Bool = true) {
        viewModel.setRotatingStatus(by: CGAngle(radians: transformation.rotation))
        
        if transformation.scrollBounds != .zero {
            scrollView.bounds = transformation.scrollBounds
        }
        
        manualZoomed = transformation.manualZoomed
        scrollView.zoomScale = transformation.scale
        scrollView.contentOffset = transformation.offset
        viewModel.setBetweenOperationStatus()
        
        if transformation.maskFrame != .zero {
            viewModel.cropBoxFrame = transformation.maskFrame
        }
        
        if rotateDial {
            rotationDial?.rotateDialPlate(by: CGAngle(radians: viewModel.radians))
            adaptAngleDashboardToCropBox()
        }
    }
    
    func getTransformInfo(byTransformInfo transformInfo: Transformation) -> Transformation {
        let cropFrame = viewModel.cropOrignFrame
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
        newTransform.scrollBounds = CGRect(x: transformInfo.scrollBounds.origin.x * adjustScale,
                                           y: transformInfo.scrollBounds.origin.y * adjustScale,
                                           width: transformInfo.scrollBounds.width * adjustScale,
                                           height: transformInfo.scrollBounds.height * adjustScale)
        
        return newTransform
    }
    
    func getTransformInfo(byNormalizedInfo normailizedInfo: CGRect) -> Transformation {
        let cropFrame = viewModel.cropBoxFrame
        
        let scale: CGFloat = min(1/normailizedInfo.width, 1/normailizedInfo.height)
        
        var offset = cropFrame.origin
        offset.x = cropFrame.width * normailizedInfo.origin.x * scale
        offset.y = cropFrame.height * normailizedInfo.origin.y * scale
        
        var maskFrame = cropFrame
        
        if normailizedInfo.width > normailizedInfo.height {
            let adjustScale = 1 / normailizedInfo.width
            maskFrame.size.height = normailizedInfo.height * cropFrame.height * adjustScale
            maskFrame.origin.y += (cropFrame.height - maskFrame.height) / 2
        } else if normailizedInfo.width < normailizedInfo.height {
            let adjustScale = 1 / normailizedInfo.height
            maskFrame.size.width = normailizedInfo.width * cropFrame.width * adjustScale
            maskFrame.origin.x += (cropFrame.width - maskFrame.width) / 2
        }
        
        let manualZoomed = (scale != 1.0)
        let transformantion = Transformation(offset: offset,
                                             rotation: 0,
                                             scale: scale,
                                             manualZoomed: manualZoomed,
                                             intialMaskFrame: .zero,
                                             maskFrame: maskFrame,
                                             scrollBounds: .zero)
        return transformantion
    }
    
    func processPresetTransformation(completion: (Transformation) -> Void) {
        switch cropViewConfig.presetTransformationType {
        case .presetInfo(let transformInfo):
            var newTransform = getTransformInfo(byTransformInfo: transformInfo)
            
            // The first transform is just for retrieving the final cropBoxFrame
            transform(byTransformInfo: newTransform, rotateDial: false)
            
            // The second transform is for adjusting the scale of transformInfo
            let adjustScale = (viewModel.cropBoxFrame.width / viewModel.cropOrignFrame.width)
            / (transformInfo.maskFrame.width / transformInfo.intialMaskFrame.width)
            newTransform.scale *= adjustScale
            transform(byTransformInfo: newTransform)
            completion(transformInfo)
        case .presetNormalizedInfo(let normailizedInfo):
            let transformInfo = getTransformInfo(byNormalizedInfo: normailizedInfo)
            transform(byTransformInfo: transformInfo)
            scrollView.frame = transformInfo.maskFrame
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
        scrollView.removeFromSuperview()
        cropOverlayView.removeFromSuperview()
        rotationDial?.removeFromSuperview()
        
        if forceFixedRatio {
            aspectRatioLockEnabled = true
        } else {
            aspectRatioLockEnabled = false
        }
        
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
        let zeroPoint = cropOverlayView.center
        
        let translation =  CGPoint(x: (point.x - zeroPoint.x), y: (point.y - zeroPoint.y))
        
        var scaleX = scrollView.zoomScale
        var scaleY = scrollView.zoomScale
        
        if viewModel.horizontallyFlip {
            if viewModel.rotationType.isRotateByMultiple180 {
                scaleX = -scaleX
            } else {
                scaleY = -scaleY
            }
        }
        
        if viewModel.verticallyFlip {
            if viewModel.rotationType.isRotateByMultiple180 {
                scaleY = -scaleY
            } else {
                scaleX = -scaleX
            }
        }
        
        return CropInfo(
            translation: translation,
            rotation: getTotalRadians(),
            scaleX: scaleX,
            scaleY: scaleY,
            cropSize: cropOverlayView.frame.size,
            imageViewSize: imageContainer.bounds.size
        )
    }
    
    func getExpectedCropImageSize() -> CGSize {
        image.getExpectedCropImageSize(by: getCropInfo())
    }
}
