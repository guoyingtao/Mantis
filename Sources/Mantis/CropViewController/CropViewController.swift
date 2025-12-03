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

open class CropViewController: UIViewController {
    public weak var delegate: CropViewControllerDelegate?
    public var config = Mantis.Config() {
        didSet {
            if config.enableUndoRedo {
                TransformStack.shared.transformDelegate = self
            }
        }
    }
    
    var cropView: CropViewProtocol! {
        didSet {
            if config.cropToolbarConfig.toolbarButtonOptions.contains(.autoAdjust) {
                imageAdjustHelper = ImageAutoAdjustHelper(image: cropView.image)
            }
        }
    }
    var cropToolbar: CropToolbarProtocol!
    private var imageAdjustHelper: ImageAutoAdjustHelper?
    
    private var ratioPresenter: RatioPresenter?
    private var ratioSelector: RatioSelector?
    private var stackView: UIStackView?
    private var cropStackView: UIStackView!
    private var initialLayout = false
    private var disableRotation = false
    
    private lazy var _undoManager: UndoManager = {
        return UndoManager()
    }()
   
    private var isCropStateUserGenerated: Bool = false
    
    private var previousCropState: CropState! {
        didSet {
            isCropStateUserGenerated = true
        }
    }
    
    private var currentCropState: CropState! {
        didSet {
            isCropStateUserGenerated = false
        }
    }
    
    open override var keyCommands: [UIKeyCommand]? {
        let zoomInCommand = UIKeyCommand(input: "+", modifierFlags: .command, action: #selector(zoomIn))
        zoomInCommand.discoverabilityTitle = "Zoom In"
        
        let zoomOutCommand = UIKeyCommand(input: "-", modifierFlags: .command, action: #selector(zoomOut))
        zoomOutCommand.discoverabilityTitle = "Zoom Out"
        
        return [zoomInCommand, zoomOutCommand]
    }
    
    deinit {
        print("CropViewController deinit.")
    }

    required public init(config: Mantis.Config = Mantis.Config()) {
        self.config = config
        
        switch config.cropViewConfig.cropShapeType {
        case .circle, .square, .heart:
            self.config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
        default:
            break
        }

        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func createRatioSelector() {
        let fixedRatioManager = getFixedRatioManager()
        ratioSelector = RatioSelector(type: fixedRatioManager.type,
                                      originalRatioH: fixedRatioManager.originalRatioH,
                                      ratios: fixedRatioManager.ratios)
        ratioSelector?.didGetRatio = { [weak self] ratio in
            self?.setFixedRatio(ratio)
        }
    }
    
    private func createCropToolbar() {
        cropToolbar.delegate = self
        
        switch config.presetFixedRatioType {
        case .alwaysUsingOnePresetFixedRatio(let ratio):
                config.cropToolbarConfig.includeFixedRatiosSettingButton = false
                                
            if case .none = config.cropViewConfig.presetTransformationType {
                    setFixedRatio(ratio)
                }
                
        case .canUseMultiplePresetFixedRatio(let defaultRatio):
                if defaultRatio > 0 {
                    setFixedRatio(defaultRatio)
                    cropView.aspectRatioLockEnabled = true
                    config.cropToolbarConfig.presetRatiosButtonSelected = true
                }
                
                config.cropToolbarConfig.includeFixedRatiosSettingButton = true
        }
        
        cropToolbar.createToolbarUI(config: config.cropToolbarConfig)                
    }
    
    private func getRatioType() -> RatioType {
        switch config.cropToolbarConfig.fixedRatiosShowType {
        case .adaptive:
            return cropView.getRatioType(byImageIsOriginalHorizontal: cropView.image.isHorizontal())
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }
    
    private func getFixedRatioManager() -> FixedRatioManager {
        let type: RatioType = getRatioType()
        
        let ratio = cropView.getImageHorizontalToVerticalRatio()
        
        return FixedRatioManager(type: type,
                                 originalRatioH: ratio,
                                 ratioOptions: config.ratioOptions,
                                 customRatios: config.customRatioItems.compactMap { $0 })
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

#if targetEnvironment(macCatalyst)
        modalPresentationStyle = .fullScreen
        navigationController?.modalPresentationStyle = .fullScreen
#endif
        view.backgroundColor = .black
        
        cropView.initialSetup(delegate: self, presetFixedRatioType: config.presetFixedRatioType)
        createCropToolbar()
        if config.cropToolbarConfig.ratioCandidatesShowType == .alwaysShowRatioList
            && config.cropToolbarConfig.includeFixedRatiosSettingButton {
            createRatioSelector()
        }
        initLayout()
        updateLayout()
        showImageAutoAdjustStatusIfNeeded()
    }
    
    func showImageAutoAdjustStatusIfNeeded() {
        if let imageAdjustHelper = imageAdjustHelper {
            if imageAdjustHelper.detectHorizon() {
                cropToolbar.handleImageAutoAdjustable()
            }
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initialLayout == false {
            guard cropView.bounds.size != .zero else {
                return
            }
            
            initialLayout = true
            view.layoutIfNeeded()
            cropView.resetComponents()
            
            cropView.processPresetTransformation { [weak self] transformation in
                guard let self = self else { return }
                if case .alwaysUsingOnePresetFixedRatio(let ratio) = self.config.presetFixedRatioType {
                    self.cropToolbar.handleFixedRatioSetted(ratio: ratio)
                    self.cropView.handlePresetFixedRatio(ratio, transformation: transformation)
                }
            }
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.top, .bottom]
    }
    
    // It is triggered by (1) - device rotation or (2) - split view operations on iPad
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        cropView.prepareForViewWillTransition()
        handleViewWillTransition()
    }
    
    @objc func zoomIn() {
        cropView.zoomIn()
    }
    
    @objc func zoomOut() {
        cropView.zoomOut()
    }
    
    @objc func handleViewWillTransition() {
        let currentOrientation = Orientation.interfaceOrientation
        
        guard currentOrientation != .unknown else { return }
        
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
            self?.cropView.handleViewWillTransition()
        }
    }    
    
    private func setFixedRatio(_ ratio: Double, zoom: Bool = true) {
        cropToolbar.handleFixedRatioSetted(ratio: ratio)
        cropView.setFixedRatio(ratio, zoom: zoom, presetFixedRatioType: config.presetFixedRatioType)
    }
    
    private func setFreeRatio() {
        resetRatioButton()
    }
    
    private func handleCancel() {
        delegate?.cropViewControllerDidCancel(self, original: cropView.image)
    }
    
    private func resetRatioButton() {
        cropView.setFreeCrop()
        cropToolbar.handleFixedRatioUnSetted()
    }
    
    private func isNeedToResetRatioButton() -> Bool {
        var needToResetRatioButton = false
        
        switch config.presetFixedRatioType {
        case .canUseMultiplePresetFixedRatio(let defaultRatio):
            if defaultRatio == 0 {
                needToResetRatioButton = true
            }
        default:
            break
        }

        return needToResetRatioButton
    }
    
    @objc private func handleSetRatio() {
        
        if cropView.aspectRatioLockEnabled && isNeedToResetRatioButton() {
            resetRatioButton()
            return
        }
        
        guard let presentSourceView = cropToolbar.getRatioListPresentSourceView() else {
            return
        }
        
        let fixedRatioManager = getFixedRatioManager()
        
        guard !fixedRatioManager.ratios.isEmpty else { return }
        
        if fixedRatioManager.ratios.count == 1 {
            let ratioItem = fixedRatioManager.ratios[0]
            let ratioValue = (fixedRatioManager.type == .horizontal) ? ratioItem.ratioH : ratioItem.ratioV
            setFixedRatio(ratioValue)
            return
        }
        
        ratioPresenter = RatioPresenter(type: fixedRatioManager.type,
                                        originalRatioH: fixedRatioManager.originalRatioH,
                                        ratios: fixedRatioManager.ratios,
                                        fixRatiosShowType: config.cropToolbarConfig.fixedRatiosShowType)
        ratioPresenter?.didGetRatio = {[weak self] ratio in
            self?.setFixedRatio(ratio, zoom: false)
        }
        ratioPresenter?.present(by: self, in: presentSourceView)
    }
    
    private func handleReset() {
              
        var previous: CropState! = nil

        if config.enableUndoRedo {
            previous = cropView.makeCropState()
        }
        
        if isNeedToResetRatioButton() {
            resetRatioButton()
        }
        
        cropView.reset()
        ratioSelector?.reset()
        ratioSelector?.update(fixedRatioManager: getFixedRatioManager())
        showImageAutoAdjustStatusIfNeeded()
        
        if config.enableUndoRedo {
            let current = cropView.makeCropState()
            TransformStack
                .shared
                .pushTransformRecordOntoStack(transformType: .resetTransforms,
                                              previous: previous,
                                              current: current,
                                              userGenerated: true)
        }
    }
    
    private func handleRotate(withRotateType rotateType: RotateBy90DegreeType) {
        if !disableRotation {
            disableRotation = true
            cropView.rotateBy90(withRotateType: rotateType) { [weak self] in
                self?.disableRotation = false
                self?.ratioSelector?.update(fixedRatioManager: self?.getFixedRatioManager())
            }
        }        
    }
    
    private func handleTransform(with cropState: CropState) {
        
        cropView.applyCropState(with: cropState)
        
        view.setNeedsLayout()
    }
    
    private func handleAlterCropper90Degree() {
        cropView.handleAlterCropper90Degree()
    }
    
    private func handleHorizontallyFlip() {
        cropView.horizontallyFlip()
    }
    
    private func handleVerticallyFlip() {
        cropView.verticallyFlip()
    }
    
    private func handleAutoAdjust(isActive: Bool) {
        if let angle = imageAdjustHelper?.adjustAngle {
            cropView.reset()
            if isActive {
                cropView.rotate(by: angle)
            }
        }
    }
    
    private func handleCrop() {
        crop()
    }
}

// Auto layout
extension CropViewController {
    private func initLayout() {
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
        
        stackView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        stackView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        stackView?.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        stackView?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    }
    
    private func setStackViewAxis() {
        if Orientation.treatAsPortrait {
            stackView?.axis = .vertical
        } else if Orientation.isLandscape {
            stackView?.axis = .horizontal
        }
    }
    
    private func changeStackViewOrder() {
        guard config.showAttachedCropToolbar else {
            stackView?.removeArrangedSubview(cropStackView)
            stackView?.addArrangedSubview(cropStackView)
            view.layoutIfNeeded()
            return
        }
        
        stackView?.removeArrangedSubview(cropStackView)
        stackView?.removeArrangedSubview(cropToolbar)
        
        if Orientation.treatAsPortrait || Orientation.isLandscapeRight {
            stackView?.addArrangedSubview(cropStackView)
            stackView?.addArrangedSubview(cropToolbar)
        } else if Orientation.isLandscapeLeft {
            stackView?.addArrangedSubview(cropToolbar)
            stackView?.addArrangedSubview(cropStackView)
        }
    }
            
    private func updateLayout() {
        setStackViewAxis()
        cropToolbar.respondToOrientationChange()
        changeStackViewOrder()
    }
}

extension CropViewController: CropViewDelegate {    
    func cropViewDidBecomeResettable(_ cropView: CropViewProtocol) {
        cropToolbar.handleCropViewDidBecomeResettable()
        delegate?.cropViewControllerDidImageTransformed(self, transformation: cropView.makeTransformation())
        delegate?.cropViewController(self, didBecomeResettable: true)
        
        if config.enableUndoRedo {
            guard let previous = previousCropState else { return }
            let userGenerated = isCropStateUserGenerated
            currentCropState = cropView.makeCropState()
            
            if previous != currentCropState {
                TransformStack
                    .shared
                    .pushTransformRecordOntoStack(transformType: .transform,
                                                  previous: previous, current:
                                                    currentCropState,
                                                  userGenerated: userGenerated)
            }
            
            previousCropState = nil
            currentCropState = nil
        }
    }
    
    func cropViewDidBecomeUnResettable(_ cropView: CropViewProtocol) {
        cropToolbar.handleCropViewDidBecomeUnResettable()
        delegate?.cropViewController(self, didBecomeResettable: false)
    }
    
    func cropViewDidBeginResize(_ cropView: CropViewProtocol) {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
        cropToolbar.handleImageNotAutoAdjustable()
        delegate?.cropViewControllerDidBeginResize(self)
    }
    
    func cropViewDidBeginCrop(_ cropView: CropViewProtocol) {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
    }
    
    func cropViewDidEndResize(_ cropView: CropViewProtocol) {
        delegate?.cropViewControllerDidEndResize(self,
                                                 original: cropView.image,
                                                 cropInfo: cropView.getCropInfo())
    }
}

extension CropViewController: CropToolbarDelegate {
    
    public func didSelectUndo() {
        undo()
    }
    
    public func didSelectRedo() {
        redo()
    }
    
    public func undoActionName() -> String {
        return _undoManager.undoActionName
    }
    
    public func redoActionName() -> String {
        return _undoManager.redoActionName
    }
    
    public func isUndoSupported() -> Bool {
        return config.enableUndoRedo
    }
    
    public func didSelectHorizontallyFlip(_ cropToolbar: CropToolbarProtocol? = nil) {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
        handleHorizontallyFlip()
    }
    
    public func didSelectVerticallyFlip(_ cropToolbar: CropToolbarProtocol? = nil) {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
        handleVerticallyFlip()
    }
    
    public func didSelectCancel(_ cropToolbar: CropToolbarProtocol? = nil) {
        handleCancel()
    }
    
    public func didSelectCrop(_ cropToolbar: CropToolbarProtocol? = nil) {
        handleCrop()
    }
    
    public func didSelectCounterClockwiseRotate(_ cropToolbar: CropToolbarProtocol? = nil) {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
        handleRotate(withRotateType: .counterClockwise)
    }
    
    public func didSelectClockwiseRotate(_ cropToolbar: CropToolbarProtocol? = nil) {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
        handleRotate(withRotateType: .clockwise)
    }
    
    public func didSelectReset(_ cropToolbar: CropToolbarProtocol? = nil) {
        handleReset()
    }
    
    public func didSelectSetRatio(_ cropToolbar: CropToolbarProtocol? = nil) {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
        handleSetRatio()
    }
    
    public func didSelectRatio(_ cropToolbar: CropToolbarProtocol? = nil, ratio: Double) {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
        setFixedRatio(ratio)
    }
    
    public func didSelectFreeRatio(_ cropToolbar: CropToolbarProtocol? = nil) {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
        setFreeRatio()
    }
    
    public func didSelectAlterCropper90Degree(_ cropToolbar: CropToolbarProtocol? = nil) {
        handleAlterCropper90Degree()
    }
    
    public func didSelectAutoAdjust(_ cropToolbar: CropToolbarProtocol?, isActive: Bool) {
        handleAutoAdjust(isActive: isActive)
    }
}

// API
extension CropViewController {
    @available(iOS 13.0, *)
    public func crop(by cropInfo: CropInfo) {
        guard let image = cropView.image.crop(by: cropInfo) else {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.delegate?.cropViewControllerDidFailToCrop(self, original: cropView.image)
            }
            return
        }
        
        let transformation = cropView.makeTransformation()
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            delegate?.cropViewControllerDidCrop(self,
                                                cropped: image,
                                                transformation: transformation,
                                                cropInfo: cropInfo)
        }
    }
        
    public func crop() {
        switch config.cropMode {
        case .sync:
            let cropOutput = cropView.crop()
            handleCropOutput(cropOutput)
        case .async:
            cropView.asyncCrop(completion: handleCropOutput)
        }
        
        func handleCropOutput(_ cropOutput: CropOutput) {
            guard let image = cropOutput.croppedImage else {
                delegate?.cropViewControllerDidFailToCrop(self, original: cropView.image)
                return
            }
            
            delegate?.cropViewControllerDidCrop(self,
                                                cropped: image,
                                                transformation: cropOutput.transformation,
                                                cropInfo: cropOutput.cropInfo)
        }
    }
    
    public func process(_ image: UIImage) -> UIImage? {
        return cropView.crop(image).croppedImage
    }
    
    public func getExpectedCropImageSize() -> CGSize {
        cropView.getExpectedCropImageSize()
    }
    
    public func update(_ image: UIImage) {
        cropView.update(image)
    }
}

extension CropViewController: TransformDelegate {
   
    func updateEnableStateForUndo(_ enable: Bool) {
        if config.enableUndoRedo {
            delegate?.cropViewController(self, didUpdateEnableStateForUndo: enable)
        }
    }
    
    func updateEnableStateForRedo(_ enable: Bool) {
        if config.enableUndoRedo {
            delegate?.cropViewController(self, didUpdateEnableStateForRedo: enable)
        }
    }
    
    func updateEnableStateForReset(_ enable: Bool) {
        if config.enableUndoRedo {
            delegate?.cropViewController(self, didUpdateEnableStateForReset: enable)
        }
    }
    
    func getUndoManager() -> UndoManager {
        return _undoManager
    }
    
    func undo() {
        if config.enableUndoRedo {
            if _undoManager.canUndo {
                _undoManager.undo()
            }
        }
    }
    
    func redo() {
        if config.enableUndoRedo {
            if _undoManager.canRedo {
                _undoManager.redo()
            }
        }
    }
    
    func isRedoEnabled() -> Bool {
        if config.enableUndoRedo {
            return _undoManager.canRedo
        } else {
            return false
        }
    }
    
    func isUndoEnabled() -> Bool {
        if config.enableUndoRedo {
            return _undoManager.canUndo
        } else {
            return false
        }
    }
    
    func updateCropState(_ cropState: CropState) {
        handleTransform(with: cropState)
    }
}
