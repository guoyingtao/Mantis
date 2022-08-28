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
    
    var image: UIImage {
        didSet {
            imageContainer.image = image
        }
    }
    let viewModel: CropViewModel
    
    weak var delegate: CropViewDelegate? {
        didSet {
            checkImageStatusChanged()
        }
    }
    
    var aspectRatioLockEnabled = false

    // Referred to in extension
    let imageContainer: ImageContainer
    let gridOverlayView: CropOverlayView
    var rotationDial: RotationDial?

    lazy var scrollView = CropScrollView(frame: bounds,
                                         minimumZoomScale: cropViewConfig.minimumZoomScale,
                                         maximumZoomScale: cropViewConfig.maximumZoomScale)
    lazy var cropMaskViewManager = CropMaskViewManager(with: self,
                                                       cropRatio: CGFloat(getImageRatioH()),
                                                       cropShapeType: cropViewConfig.cropShapeType,
                                                       cropMaskVisualEffectType: cropViewConfig.cropMaskVisualEffectType)

    var manualZoomed = false
    var forceFixedRatio = false
    var checkForForceFixedRatioFlag = false
    let cropViewConfig: CropViewConfig
    
    private var cropFrameKVO: NSKeyValueObservation?
    
    deinit {
        print("CropView deinit.")
    }
    
    init(
        image: UIImage,
        cropViewConfig: CropViewConfig = Mantis.Config().cropViewConfig
    ) {
        self.image = image

        self.viewModel = CropViewModel(
            cropViewPadding: cropViewConfig.padding,
            hotAreaUnit: cropViewConfig.cropBoxHotAreaUnit
        )

        self.cropViewConfig = cropViewConfig
        
        imageContainer = ImageContainer()
        gridOverlayView = CropOverlayView()

        super.init(frame: CGRect.zero)
        
        self.viewModel.statusChanged = { [weak self] status in
            self?.render(by: status)
        }
        
        cropFrameKVO = viewModel.observe(\.cropBoxFrame,
                                         options: [.new, .old]) { [unowned self] _, changed in
            guard let cropFrame = changed.newValue else { return }
            self.gridOverlayView.frame = cropFrame
            
            var cropRatio: CGFloat = 1.0
            if self.gridOverlayView.frame.height != 0 {
                cropRatio = self.gridOverlayView.frame.width / self.gridOverlayView.frame.height
            }
            
            self.cropMaskViewManager.adaptMaskTo(match: cropFrame, cropRatio: cropRatio)
        }
                
        initalRender()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        case .rotating(let angle):
            viewModel.degrees = angle.degrees
            rotateScrollView()
        case .degree90Rotating:
            cropMaskViewManager.showVisualEffectBackground()
            gridOverlayView.isHidden = true
            rotationDial?.isHidden = true
        case .touchImage:
            cropMaskViewManager.showDimmingBackground()
            gridOverlayView.gridLineNumberType = .crop
            gridOverlayView.setGrid(hidden: false, animated: true)
        case .touchCropboxHandle(let tappedEdge):
            gridOverlayView.handleEdgeTouched(with: tappedEdge)
            rotationDial?.isHidden = true
            cropMaskViewManager.showDimmingBackground()
        case .touchRotationBoard:
            gridOverlayView.gridLineNumberType = .rotate
            gridOverlayView.setGrid(hidden: false, animated: true)
            cropMaskViewManager.showDimmingBackground()
        case .betweenOperation:
            gridOverlayView.handleEdgeUntouched()
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
    
    private func setupUI() {
        setupScrollView()
        imageContainer.image = image
        
        scrollView.addSubview(imageContainer)
        scrollView.imageContainer = imageContainer
        scrollView.minimumZoomScale = cropViewConfig.minimumZoomScale
        scrollView.maximumZoomScale = cropViewConfig.maximumZoomScale
        
        if cropViewConfig.minimumZoomScale > 1 {
            scrollView.zoomScale = cropViewConfig.minimumZoomScale
        }
        
        setGridOverlayView()
    }
    
    func resetUIFrame() {
        cropMaskViewManager.removeMaskViews()
        cropMaskViewManager.setup(in: self, cropRatio: CGFloat(getImageRatioH()))
        viewModel.resetCropFrame(by: getInitialCropBoxRect())
                
        scrollView.transform = .identity
        scrollView.resetBy(rect: viewModel.cropBoxFrame)
        
        imageContainer.frame = CGRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
        scrollView.contentOffset = CGPoint(x: (imageContainer.frame.width - scrollView.frame.width) / 2,
                                           y: (imageContainer.frame.height - scrollView.frame.height) / 2)

        gridOverlayView.superview?.bringSubviewToFront(gridOverlayView)
        
        setupAngleDashboard()
        
        if aspectRatioLockEnabled {
            setFixedRatioCropBox()
        }
    }
    
    func adaptForCropBox() {
        resetUIFrame()
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
    }
    
    private func setGridOverlayView() {
        gridOverlayView.isUserInteractionEnabled = false
        gridOverlayView.gridHidden = true
        addSubview(gridOverlayView)
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
        
        rotationDial.setRotationCenter(by: gridOverlayView.center, of: self)
        
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
            rotationDial.frame.origin.x = gridOverlayView.frame.origin.x +  (gridOverlayView.frame.width - rotationDial.frame.width) / 2
            rotationDial.frame.origin.y = gridOverlayView.frame.maxY
        } else if Orientation.isLandscapeLeft {
            rotationDial.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            rotationDial.frame.origin.x = gridOverlayView.frame.maxX
            rotationDial.frame.origin.y = gridOverlayView.frame.origin.y + (gridOverlayView.frame.height - rotationDial.frame.height) / 2
        } else if Orientation.isLandscapeRight {
            rotationDial.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            rotationDial.frame.origin.x = gridOverlayView.frame.minX - rotationDial.frame.width
            rotationDial.frame.origin.y = gridOverlayView.frame.origin.y + (gridOverlayView.frame.height - rotationDial.frame.height) / 2
        }
    }
    
    func updateCropBoxFrame(with point: CGPoint) {
        let cropViewMinimumBoxSize = cropViewConfig.minimumBoxSize

        let contentFrame = getContentBounds()
        let newCropBoxFrame = viewModel.getNewCropBoxFrame(with: point, and: contentFrame, aspectRatioLockEnabled: aspectRatioLockEnabled)
        
        let contentBounds = getContentBounds()
        
        guard newCropBoxFrame.width >= cropViewMinimumBoxSize
                && newCropBoxFrame.minX >= contentBounds.minX
                && newCropBoxFrame.maxX <= contentBounds.maxX
                && newCropBoxFrame.height >= cropViewMinimumBoxSize
                && newCropBoxFrame.minY >= contentBounds.minY
                && newCropBoxFrame.maxY <= contentBounds.maxY else {
            return
        }
        
        if imageContainer.contains(rect: newCropBoxFrame, fromView: self) {
            viewModel.cropBoxFrame = newCropBoxFrame
        } else {
            let minX = max(viewModel.cropBoxFrame.minX, newCropBoxFrame.minX)
            let minY = max(viewModel.cropBoxFrame.minY, newCropBoxFrame.minY)
            let maxX = min(viewModel.cropBoxFrame.maxX, newCropBoxFrame.maxX)
            let maxY = min(viewModel.cropBoxFrame.maxY, newCropBoxFrame.maxY)

            var rect: CGRect
            
            rect = CGRect(x: minX, y: minY, width: newCropBoxFrame.width, height: maxY - minY)
            if imageContainer.contains(rect: rect, fromView: self) {
                viewModel.cropBoxFrame = rect
                return
            }
            
            rect = CGRect(x: minX, y: minY, width: maxX - minX, height: newCropBoxFrame.height)
            if imageContainer.contains(rect: rect, fromView: self) {
                viewModel.cropBoxFrame = rect
                return
            }
            
            rect = CGRect(x: newCropBoxFrame.minX, y: minY, width: newCropBoxFrame.width, height: maxY - minY)
            if imageContainer.contains(rect: rect, fromView: self) {
                viewModel.cropBoxFrame = rect
                return
            }

            rect = CGRect(x: minX, y: newCropBoxFrame.minY, width: maxX - minX, height: newCropBoxFrame.height)
            if imageContainer.contains(rect: rect, fromView: self) {
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
        
        let leftTopPoint = gridOverlayView.convert(CGPoint(x: 0, y: 0), to: imageContainer)
        let point = CGPoint(x: leftTopPoint.x / imageContainer.bounds.width, y: leftTopPoint.y / imageContainer.bounds.height)
        return point
    }
    
    fileprivate func getImageRightBottomAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.cropRightBottomOnImage
        }
        
        let rightBottomPoint = gridOverlayView.convert(CGPoint(x: gridOverlayView.bounds.width, y: gridOverlayView.bounds.height), to: imageContainer)
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
        if !imageContainer.contains(rect: gridOverlayView.frame, fromView: self, tolerance: 0.25) {
            scrollView.zoomScaleToBound(animated: true)
        }
    }
    
    fileprivate func updatePosition(by radians: CGFloat) {
        let width = abs(cos(radians)) * gridOverlayView.frame.width + abs(sin(radians)) * gridOverlayView.frame.height
        let height = abs(sin(radians)) * gridOverlayView.frame.width + abs(cos(radians)) * gridOverlayView.frame.height
        
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
            let width = abs(cos(radians)) * gridOverlayView.frame.width + abs(sin(radians)) * gridOverlayView.frame.height
            let height = abs(sin(radians)) * gridOverlayView.frame.width + abs(cos(radians)) * gridOverlayView.frame.height

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
    func crop(_ image: UIImage) -> CropOutput {
        let cropInfo = getCropInfo()
        
        let transformation = Transformation(
            offset: scrollView.contentOffset,
            rotation: getTotalRadians(),
            scale: scrollView.zoomScale,
            manualZoomed: manualZoomed,
            intialMaskFrame: getInitialCropBoxRect(),
            maskFrame: gridOverlayView.frame,
            scrollBounds: scrollView.bounds
        )
        
        guard let croppedImage = image.crop(by: cropInfo) else {
            return (nil, transformation, cropInfo)
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
    
    func getCropInfo() -> CropInfo {        
        let rect = imageContainer.convert(imageContainer.bounds,
                                          to: self)
        let point = rect.center
        let zeroPoint = gridOverlayView.center
        
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
            cropSize: gridOverlayView.frame.size,
            imageViewSize: imageContainer.bounds.size
        )
    }
    
    func getTotalRadians() -> CGFloat {
        return viewModel.getTotalRadians()
    }
    
    func crop() -> CropOutput {
        return crop(image)
    }
        
    func handleDeviceRotated() {
        viewModel.resetCropFrame(by: getInitialCropBoxRect())
        
        scrollView.transform = CGAffineTransform(scaleX: 1, y: 1)        
        scrollView.resetBy(rect: viewModel.cropBoxFrame)
        
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
    
    func rotateBy90(rotateAngle: CGFloat, completion: @escaping () -> Void = {}) {
        viewModel.setDegree90RotatingStatus()
        let rorateDuration = 0.25                
        var rect = gridOverlayView.frame        
        rect.size.width = gridOverlayView.frame.height
        rect.size.height = gridOverlayView.frame.width
        
        let newRect = GeometryHelper.getInscribeRect(fromOutsideRect: getContentBounds(), andInsideRect: rect)
        
        var newRotateAngle = rotateAngle
        
        if viewModel.horizontallyFlip {
            newRotateAngle = -newRotateAngle
        }
        
        if viewModel.verticallyFlip {
            newRotateAngle = -newRotateAngle
        }
        
        UIView.animate(withDuration: rorateDuration, animations: {
            self.viewModel.cropBoxFrame = newRect
            self.scrollView.transform = self.scrollView.transform.rotated(by: newRotateAngle)
            self.updatePositionFor90Rotation(by: newRotateAngle + self.viewModel.radians)
        }, completion: {[weak self] _ in
            guard let self = self else { return }
            self.scrollView.updateMinZoomScale()
            self.viewModel.rotateBy90(rotateAngle: newRotateAngle)
            self.viewModel.setBetweenOperationStatus()
            completion()
        })
    }
    
    func reset() {
        scrollView.removeFromSuperview()
        gridOverlayView.removeFromSuperview()
        rotationDial?.removeFromSuperview()
        
        if forceFixedRatio {
            aspectRatioLockEnabled = true
        } else {
            aspectRatioLockEnabled = false
        }
        
        viewModel.reset(forceFixedRatio: forceFixedRatio)
        resetUIFrame()
        delegate?.cropViewDidBecomeUnResettable(self)
        delegate?.cropViewDidEndResize(self)
    }
    
    func prepareForDeviceRotation() {
        viewModel.setDegree90RotatingStatus()
        saveAnchorPoints()
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
    
    func getExpectedCropImageSize() -> CGSize {
        image.getExpectedCropImageSize(by: getCropInfo())
    }
    
    func horizontallyFlip() {
        viewModel.horizontallyFlip.toggle()
        flip(isHorizontal: true)
    }
    
    func verticallyFlip() {
        viewModel.verticallyFlip.toggle()
        flip(isHorizontal: false)
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
