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
                transformStack.transformDelegate = self
            }
        }
    }

    /// Undo/redo bookkeeping scoped to this crop session, so concurrent
    /// sessions (e.g. multiple windows) keep independent undo histories.
    let transformStack = TransformStack()
    
    var cropView: CropViewProtocol! {
        didSet {
            if config.cropToolbarConfig.toolbarButtonOptions.contains(.autoAdjust) {
                imageAdjustHelper = ImageAutoAdjustHelper(image: cropView.image)
            }
        }
    }
    var cropToolbar: CropToolbarProtocol!
    var imageAdjustHelper: ImageAutoAdjustHelper?
    
    var ratioPresenter: RatioPresenter?
    var ratioSelector: RatioSelector?
    var stackView: UIStackView?
    var cropStackView: UIStackView!
    var initialLayout = false
    var disableRotation = false
    
    // Only decides whether handleViewWillTransition() skips a transition; layout code
    // reads Orientation directly. Tests replace it to drive orientations such as .unknown.
    var interfaceOrientationProvider: () -> UIInterfaceOrientation = { Orientation.interfaceOrientation }
    
    // swiftlint:disable:next identifier_name
    lazy var _undoManager: UndoManager = {
        return UndoManager()
    }()
   
    var isCropStateUserGenerated: Bool = false
    
    var previousCropState: CropState! {
        didSet {
            isCropStateUserGenerated = true
        }
    }
    
    var currentCropState: CropState! {
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
    
    override open func viewDidLoad() {
        super.viewDidLoad()

#if targetEnvironment(macCatalyst)
        modalPresentationStyle = .fullScreen
        navigationController?.modalPresentationStyle = .fullScreen
#endif
        switch config.appearanceMode {
        case .forceDark:
            overrideUserInterfaceStyle = .dark
        case .forceLight:
            overrideUserInterfaceStyle = .light
        case .system:
            overrideUserInterfaceStyle = .unspecified
        }

        view.backgroundColor = AppearanceColorPreset.mainBackground(for: config.appearanceMode)

        // The config property observer doesn't fire when config is set in init,
        // so wire up the undo stack here as well.
        if config.enableUndoRedo {
            transformStack.transformDelegate = self
        }

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
            stackView?.layoutIfNeeded()
            cropStackView.layoutIfNeeded()
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
    
    // Called whenever UIKit changes this view's size: interface rotation, iPad multitasking
    // (Split View, Stage Manager) or a foldable iPhone switching displays.
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        handleViewWillTransition()
    }
    
    @objc func zoomIn() {
        cropView.zoomIn()
    }
    
    @objc func zoomOut() {
        cropView.zoomOut()
    }
    
    func handleViewWillTransition() {
        // Bail out before prepareForViewWillTransition(): it hides the crop box and
        // rotation control until cropView.handleViewWillTransition() shows them again,
        // so returning after it would leave them hidden.
        guard interfaceOrientationProvider() != .unknown else { return }

        cropView.prepareForViewWillTransition()
        updateLayout()
        view.layoutIfNeeded()
        
        // When this controller is embedded in a container, its final viewDidLayoutSubviews
        // can arrive after this point. Delay cropView.handleViewWillTransition() so it
        // normally runs after that layout pass. The 0.1 s delay is a heuristic, not a guarantee.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.cropView.handleViewWillTransition()
        }
    }
}
// MARK: - Action Handlers
extension CropViewController {
    func savePreviousCropStateIfNeeded() {
        if config.enableUndoRedo {
            previousCropState = cropView.makeCropState()
        }
    }
    
    func setFixedRatio(_ ratio: Double, zoom: Bool = true) {
        cropToolbar.handleFixedRatioSetted(ratio: ratio)
        cropView.setFixedRatio(ratio, zoom: zoom, presetFixedRatioType: config.presetFixedRatioType)
    }
    
    func setFreeRatio() {
        resetRatioButton()
    }
    
    func handleCancel() {
        delegate?.cropViewControllerDidCancel(self, original: cropView.image)
    }
    
    func resetRatioButton() {
        cropView.setFreeCrop()
        cropToolbar.handleFixedRatioUnSetted()
    }
    
    func handleReset() {
              
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
            transformStack
                .pushTransformRecordOntoStack(transformType: .resetTransforms,
                                              previous: previous,
                                              current: current,
                                              userGenerated: true)
        }
    }
    
    func handleRotate(withRotateType rotateType: RotateBy90DegreeType) {
        if !disableRotation {
            disableRotation = true
            cropView.rotateBy90(withRotateType: rotateType) { [weak self] in
                self?.disableRotation = false
                self?.ratioSelector?.update(fixedRatioManager: self?.getFixedRatioManager())
            }
        }
    }
    
    func handleTransform(with cropState: CropState) {
        cropView.applyCropState(with: cropState)
        view.setNeedsLayout()
    }
    
    func handleAlterCropper90Degree() {
        cropView.handleAlterCropper90Degree()
    }
    
    func handleHorizontallyFlip() {
        cropView.horizontallyFlip()
    }
    
    func handleVerticallyFlip() {
        cropView.verticallyFlip()
    }
    
    func handleAutoAdjust(isActive: Bool) {
        if let angle = imageAdjustHelper?.adjustAngle {
            cropView.reset()
            if isActive {
                cropView.rotate(by: angle)
            }
        }
    }
    
    func handleCrop() {
        crop()
    }
}

// MARK: - Ratio Helpers
extension CropViewController {
    func createRatioSelector() {
        let fixedRatioManager = getFixedRatioManager()
        ratioSelector = RatioSelector(type: fixedRatioManager.type,
                                      originalRatioH: fixedRatioManager.originalRatioH,
                                      ratios: fixedRatioManager.ratios)
        ratioSelector?.appearanceMode = config.appearanceMode
        ratioSelector?.didGetRatio = { [weak self] ratio in
            self?.setFixedRatio(ratio)
        }
    }
    
    func createCropToolbar() {
        cropToolbar.delegate = self
        
        if let toolbar = cropToolbar as? CropToolbar {
            toolbar.appearanceMode = config.appearanceMode
        }
        
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
    
    func getRatioType() -> RatioType {
        switch config.cropToolbarConfig.fixedRatiosShowType {
        case .adaptive:
            return cropView.getRatioType(byImageIsOriginalHorizontal: cropView.image.isHorizontal())
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }
    
    func getFixedRatioManager() -> FixedRatioManager {
        let type: RatioType = getRatioType()
        
        let ratio = cropView.getImageHorizontalToVerticalRatio()
        
        return FixedRatioManager(type: type,
                                 originalRatioH: ratio,
                                 ratioOptions: config.ratioOptions,
                                 customRatios: config.customRatioItems.compactMap { $0 })
    }
    
    func isNeedToResetRatioButton() -> Bool {
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
    
    @objc func handleSetRatio() {
        
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
}
