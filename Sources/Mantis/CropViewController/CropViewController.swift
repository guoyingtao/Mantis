//
//  CropViewController.swift
//  Mantis
//
//  Created by Echo on 10/30/18.
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

public protocol CropViewControllerDelegate: class {
    func cropViewControllerDidCrop(_ cropViewController: CropViewController,
                                   cropped: UIImage, transformation: Transformation)
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage)
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage)
    
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController)
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo)    
}

public extension CropViewControllerDelegate where Self: UIViewController {
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {}
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {}
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {}   
}

public enum CropViewControllerMode {
    case normal
    case customizable    
}

public class CropViewController: UIViewController {
    /// When a CropViewController is used in a storyboard,
    /// passing an image to it is needed after the CropViewController is created.
    public var image: UIImage! {
        didSet {
            cropView.image = image
        }
    }
    
    public weak var delegate: CropViewControllerDelegate?
    public var mode: CropViewControllerMode = .normal
    public var config = Mantis.Config()
    
    private var orientation: UIInterfaceOrientation = .unknown
    private lazy var cropView = CropView(image: image, viewModel: CropViewModel())
    private var cropToolbar: CropToolbarProtocol
    private var ratioPresenter: RatioPresenter?
    private var ratioSelector: RatioSelector?
    private var stackView: UIStackView?
    private var cropStackView: UIStackView!
    private var initialLayout = false
    private var disableRotation = false
    
    deinit {
        print("CropViewController deinit.")
    }
    
    init(image: UIImage,
         config: Mantis.Config = Mantis.Config(),
         mode: CropViewControllerMode = .normal,
         cropToolbar: CropToolbarProtocol = CropToolbar(frame: CGRect.zero)) {
        self.image = image
        
        self.config = config
        
        switch config.cropShapeType {
        case .circle, .square:
            self.config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
        default:
            ()
        }        
        
        self.mode = mode
        self.cropToolbar = cropToolbar
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.cropToolbar = CropToolbar(frame: CGRect.zero)
        super.init(coder: aDecoder)
    }
    
    fileprivate func createRatioSelector() {
        let fixedRatioManager = getFixedRatioManager()
        self.ratioSelector = RatioSelector(type: fixedRatioManager.type, originalRatioH: fixedRatioManager.originalRatioH, ratios: fixedRatioManager.ratios)
        self.ratioSelector?.didGetRatio = { [weak self] ratio in
            self?.setFixedRatio(ratio)
        }
    }
    
    fileprivate func createCropToolbar() {
        cropToolbar.cropToolbarDelegate = self
        
        switch(config.presetFixedRatioType) {
            case .alwaysUsingOnePresetFixedRatio(let ratio):
                config.cropToolbarConfig.includeFixedRatioSettingButton = false
                                
                if case .none = config.presetTransformationType  {
                    setFixedRatio(ratio)
                }
                
            case .canUseMultiplePresetFixedRatio(let defaultRatio):
                if (defaultRatio > 0) {
                    setFixedRatio(defaultRatio)
                    cropView.aspectRatioLockEnabled = true
                    config.cropToolbarConfig.presetRatiosButtonSelected = true
                }
                
                config.cropToolbarConfig.includeFixedRatioSettingButton = true
        }
                
        if mode == .normal {
            config.cropToolbarConfig.mode = .normal
        } else {
            config.cropToolbarConfig.mode = .simple
        }
        
        cropToolbar.createToolbarUI(config: config.cropToolbarConfig)
                
        cropToolbar.initConstraints(heightForVerticalOrientation: config.cropToolbarConfig.cropToolbarHeightForVertialOrientation, widthForHorizonOrientation: config.cropToolbarConfig.cropToolbarWidthForHorizontalOrientation)
    }
    
    private func getRatioType() -> RatioType {
        switch config.cropToolbarConfig.fixRatiosShowType {
        case .adaptive:
            return cropView.getRatioType(byImageIsOriginalisHorizontal: cropView.image.isHorizontal())
        case .horizontal:
            return .horizontal
        case .vetical:
            return .vertical
        }
    }
    
    fileprivate func getFixedRatioManager() -> FixedRatioManager {
        let type: RatioType = getRatioType()
        
        let ratio = cropView.getImageRatioH()
        
        return FixedRatioManager(type: type,
                                 originalRatioH: ratio,
                                 ratioOptions: config.ratioOptions,
                                 customRatios: config.getCustomRatioItems())
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        createCropView()
        createCropToolbar()
        if config.cropToolbarConfig.ratioCandidatesShowType == .alwaysShowRatioList && config.cropToolbarConfig.includeFixedRatioSettingButton {
            createRatioSelector()
        }
        initLayout()
        updateLayout()        
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initialLayout == false {
            initialLayout = true
            view.layoutIfNeeded()
            cropView.adaptForCropBox()
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.top, .bottom]
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        cropView.prepareForDeviceRotation()
        rotated()
    }    
    
    @objc func rotated() {
        let currentOrientation = Orientation.orientation
        
        guard currentOrientation != .unknown else { return }
        guard currentOrientation != orientation else { return }
        
        orientation = currentOrientation
        
        if UIDevice.current.userInterfaceIdiom == .phone
            && currentOrientation == .portraitUpsideDown {
            return
        }
        
        updateLayout()
        view.layoutIfNeeded()
        
        // When it is embedded in a container, the timing of viewDidLayoutSubviews
        // is different with the normal mode.
        // So delay the execution to make sure handleRotate runs after the final
        // viewDidLayoutSubviews
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.cropView.handleRotate()
        }
    }    
    
    private func setFixedRatio(_ ratio: Double, zoom: Bool = true) {
        cropToolbar.handleFixedRatioSetted(ratio: ratio)
        cropView.aspectRatioLockEnabled = true
        
        if (cropView.viewModel.aspectRatio != CGFloat(ratio)) {
            cropView.viewModel.aspectRatio = CGFloat(ratio)
            
            if case .alwaysUsingOnePresetFixedRatio = config.presetFixedRatioType {
                self.cropView.setFixedRatioCropBox(zoom: zoom)
            } else {
                UIView.animate(withDuration: 0.5) {
                    self.cropView.setFixedRatioCropBox(zoom: zoom)
                }
            }
            
        }
    }
    
    private func createCropView() {
        if !config.showRotationDial {
            cropView.angleDashboardHeight = 0
        }
        cropView.delegate = self
        cropView.clipsToBounds = true
        cropView.cropShapeType = config.cropShapeType
        cropView.cropVisualEffectType = config.cropVisualEffectType
        
        if case .alwaysUsingOnePresetFixedRatio = config.presetFixedRatioType {
            cropView.forceFixedRatio = true
        } else {
            cropView.forceFixedRatio = false
        }
    }
    
    private func processPresetTransformation(completion: (Transformation)->Void) {
        if case .presetInfo(let transformInfo) = config.presetTransformationType {
            var newTransform = getTransformInfo(byTransformInfo: transformInfo)
            
            // The first transform is just for retrieving the final cropBoxFrame
            cropView.transform(byTransformInfo: newTransform, rotateDial: false)
            
            // The second transform is for adjusting the scale of transformInfo
            let adjustScale = (cropView.viewModel.cropBoxFrame.width / cropView.viewModel.cropOrignFrame.width) / (transformInfo.maskFrame.width / transformInfo.intialMaskFrame.width)
            newTransform.scale *= adjustScale
            cropView.transform(byTransformInfo: newTransform)
            completion(transformInfo)
        } else if case .presetNormalizedInfo(let normailizedInfo) = config.presetTransformationType {
            let transformInfo = getTransformInfo(byNormalizedInfo: normailizedInfo);
            cropView.transform(byTransformInfo: transformInfo)
            cropView.scrollView.frame = transformInfo.maskFrame
            completion(transformInfo)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        processPresetTransformation() { [weak self] transform in
            guard let self = self else { return }
            if case .alwaysUsingOnePresetFixedRatio(let ratio) = self.config.presetFixedRatioType {
                self.cropView.aspectRatioLockEnabled = true
                self.cropToolbar.handleFixedRatioSetted(ratio: ratio)
                
                if ratio == 0 {
                    self.cropView.viewModel.aspectRatio = transform.maskFrame.width / transform.maskFrame.height
                } else {
                    self.cropView.viewModel.aspectRatio = CGFloat(ratio)
                    self.cropView.setFixedRatioCropBox(zoom: false, cropBox: cropView.viewModel.cropBoxFrame)
                }
            }
        }
    }
    
    private func getTransformInfo(byTransformInfo transformInfo: Transformation) -> Transformation {
        let cropFrame = cropView.viewModel.cropOrignFrame
        let contentBound = cropView.getContentBounds()
        
        let adjustScale: CGFloat
        var maskFrameWidth: CGFloat
        var maskFrameHeight: CGFloat
        
        if ( transformInfo.maskFrame.height / transformInfo.maskFrame.width >= contentBound.height / contentBound.width ) {
            maskFrameHeight = contentBound.height
            maskFrameWidth = transformInfo.maskFrame.width / transformInfo.maskFrame.height * maskFrameHeight
            adjustScale = maskFrameHeight / transformInfo.maskFrame.height
        } else {
            maskFrameWidth = contentBound.width
            maskFrameHeight = transformInfo.maskFrame.height / transformInfo.maskFrame.width * maskFrameWidth
            adjustScale = maskFrameWidth / transformInfo.maskFrame.width
        }
        
        var newTransform = transformInfo
        
        newTransform.offset = CGPoint(x:transformInfo.offset.x * adjustScale,
                                      y:transformInfo.offset.y * adjustScale)
        
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
    
    private func getTransformInfo(byNormalizedInfo normailizedInfo: CGRect) -> Transformation {
        let cropFrame = cropView.viewModel.cropBoxFrame
        
        let scale: CGFloat = min(1/normailizedInfo.width, 1/normailizedInfo.height)
        
        var offset = cropFrame.origin
        offset.x = cropFrame.width * normailizedInfo.origin.x * scale
        offset.y = cropFrame.height * normailizedInfo.origin.y * scale
        
        var maskFrame = cropFrame
        
        if (normailizedInfo.width > normailizedInfo.height) {
            let adjustScale = 1 / normailizedInfo.width
            maskFrame.size.height = normailizedInfo.height * cropFrame.height * adjustScale
            maskFrame.origin.y += (cropFrame.height - maskFrame.height) / 2
        } else if (normailizedInfo.width < normailizedInfo.height) {
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
    
    private func handleCancel() {
        self.delegate?.cropViewControllerDidCancel(self, original: self.image)
    }
    
    private func resetRatioButton() {
        cropView.aspectRatioLockEnabled = false
        cropToolbar.handleFixedRatioUnSetted()
    }
    
    @objc private func handleSetRatio() {
        if cropView.aspectRatioLockEnabled {
            resetRatioButton()
            return
        }
        
        guard let presentSourceView = cropToolbar.getRatioListPresentSourceView() else {
            return
        }
        
        let fixedRatioManager = getFixedRatioManager()
        
        guard fixedRatioManager.ratios.count > 0 else { return }
        
        if fixedRatioManager.ratios.count == 1 {
            let ratioItem = fixedRatioManager.ratios[0]
            let ratioValue = (fixedRatioManager.type == .horizontal) ? ratioItem.ratioH : ratioItem.ratioV
            setFixedRatio(ratioValue)
            return
        }
        
        ratioPresenter = RatioPresenter(type: fixedRatioManager.type,
                                        originalRatioH: fixedRatioManager.originalRatioH,
                                        ratios: fixedRatioManager.ratios,
                                        fixRatiosShowType: config.cropToolbarConfig.fixRatiosShowType)
        ratioPresenter?.didGetRatio = {[weak self] ratio in
            self?.setFixedRatio(ratio, zoom: false)
        }
        ratioPresenter?.present(by: self, in: presentSourceView)
    }
    
    private func handleReset() {
        resetRatioButton()
        cropView.reset()
        ratioSelector?.reset()
        ratioSelector?.update(fixedRatioManager: getFixedRatioManager())
    }
    
    private func handleRotate(rotateAngle: CGFloat) {
        if !disableRotation {
            disableRotation = true
            cropView.RotateBy90(rotateAngle: rotateAngle) { [weak self] in
                self?.disableRotation = false
                self?.ratioSelector?.update(fixedRatioManager: self?.getFixedRatioManager())
            }
        }
        
    }
    
    private func handleAlterCropper90Degree() {
        let ratio = Double(cropView.gridOverlayView.frame.height / cropView.gridOverlayView.frame.width)
        
        cropView.viewModel.aspectRatio = CGFloat(ratio)
        
        UIView.animate(withDuration: 0.5) {
            self.cropView.setFixedRatioCropBox()
        }
    }
    
    private func handleCrop() {
        let cropResult = cropView.crop()
        guard let image = cropResult.croppedImage else {
            delegate?.cropViewControllerDidFailToCrop(self, original: cropView.image)
            return
        }
        
        self.delegate?.cropViewControllerDidCrop(self, cropped: image, transformation: cropResult.transformation)        
    }
}

// Auto layout
extension CropViewController {
    fileprivate func initLayout() {
        cropStackView = UIStackView()
        cropStackView.axis = .vertical
        cropStackView.addArrangedSubview(cropView)
        
        if let ratioSelector = ratioSelector {
            cropStackView.addArrangedSubview(ratioSelector)
        }
        
        stackView = UIStackView()
        view.addSubview(stackView!)
        
        cropStackView?.translatesAutoresizingMaskIntoConstraints = false
        stackView?.translatesAutoresizingMaskIntoConstraints = false
        cropToolbar.translatesAutoresizingMaskIntoConstraints = false
        cropView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        stackView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        stackView?.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        stackView?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    }
    
    fileprivate func setStackViewAxis() {
        if Orientation.isPortrait {
            stackView?.axis = .vertical
        } else if Orientation.isLandscape {
            stackView?.axis = .horizontal
        }
    }
    
    fileprivate func changeStackViewOrder() {
        stackView?.removeArrangedSubview(cropStackView)
        stackView?.removeArrangedSubview(cropToolbar)
        
        if Orientation.isPortrait || Orientation.isLandscapeRight {
            stackView?.addArrangedSubview(cropStackView)
            stackView?.addArrangedSubview(cropToolbar)
        } else if Orientation.isLandscapeLeft {
            stackView?.addArrangedSubview(cropToolbar)
            stackView?.addArrangedSubview(cropStackView)
        }
    }
    
    fileprivate func updateLayout() {
        setStackViewAxis()
        cropToolbar.respondToOrientationChange()
        changeStackViewOrder()
    }
}

extension CropViewController: CropViewDelegate {
    
    func cropViewDidBecomeResettable(_ cropView: CropView) {
        cropToolbar.handleCropViewDidBecomeResettable()
    }
    
    func cropViewDidBecomeUnResettable(_ cropView: CropView) {
        cropToolbar.handleCropViewDidBecomeUnResettable()
    }
    
    func cropViewDidBeginResize(_ cropView: CropView) {
        delegate?.cropViewControllerDidBeginResize(self)
    }
    
    func cropViewDidEndResize(_ cropView: CropView) {
        delegate?.cropViewControllerDidEndResize(self, original: cropView.image, cropInfo: cropView.getCropInfo())
    }
}

extension CropViewController: CropToolbarDelegate {
    public func didSelectCancel() {
        handleCancel()
    }
    
    public func didSelectCrop() {
        handleCrop()
    }
    
    public func didSelectCounterClockwiseRotate() {
        handleRotate(rotateAngle: -CGFloat.pi / 2)
    }
    
    public func didSelectClockwiseRotate() {
        handleRotate(rotateAngle: CGFloat.pi / 2)
    }
    
    public func didSelectReset() {
        handleReset()
    }
    
    public func didSelectSetRatio() {
        handleSetRatio()
    }
    
    public func didSelectRatio(ratio: Double) {
        setFixedRatio(ratio)
    }
    
    public func didSelectAlterCropper90Degree() {
        handleAlterCropper90Degree()
    }
}

// API
extension CropViewController {
    public func crop() {
        let cropResult = cropView.crop()
        guard let image = cropResult.croppedImage else {
            delegate?.cropViewControllerDidFailToCrop(self, original: cropView.image)
            return
        }
        
        delegate?.cropViewControllerDidCrop(self, cropped: image, transformation: cropResult.transformation)
    }
    
    public func process(_ image: UIImage) -> UIImage? {
        return cropView.crop(image).croppedImage
    }
}
