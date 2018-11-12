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

public protocol CropViewControllerProtocal: class {
    func didGetCroppedImage(image: UIImage)
}

public enum CropViewControllerMode {
    case normal
    case customizable    
}

public class CropViewController: UIViewController {
    
    weak var delegate: CropViewControllerProtocal?
    
    private var orientation: UIInterfaceOrientation = .unknown
    
    private var cropToolbar: CropToolbar?
    private var ratioPresenter: RatioPresenter?
    private var cropView: CropView?

    private var cropViewTopConstraint: NSLayoutConstraint?
    private var cropViewLandscapeBottomConstraint: NSLayoutConstraint?
    private var cropViewPortraitBottomConstraint: NSLayoutConstraint?
    private var cropViewLandscapeLeftLeftConstraint: NSLayoutConstraint?
    private var cropViewLandscapeRightLeftConstraint: NSLayoutConstraint?
    private var cropViewPortraitLeftConstraint: NSLayoutConstraint?
    private var cropViewLandscapeLeftRightConstraint: NSLayoutConstraint?
    private var cropViewLandscapeRightRightConstraint: NSLayoutConstraint?
    private var cropViewPortaitRightConstraint: NSLayoutConstraint?
    
    private var toolbarWidthConstraint: NSLayoutConstraint?
    private var toolbarHeightConstraint: NSLayoutConstraint?
    private var toolbarTopConstraint: NSLayoutConstraint?
    private var toolbarLeftConstraint: NSLayoutConstraint?
    private var toolbarRightConstraint: NSLayoutConstraint?
    private var toolbarPortraitBottomConstraint: NSLayoutConstraint?
    private var toolbarLandscapeBottomConstraint: NSLayoutConstraint?
    
    private var uiConstraints: [NSLayoutConstraint?] = []
        
    private var initialLayout = false
    
    var image: UIImage?
    var mode: CropViewControllerMode = .normal
    var config: MantisConfig = MantisConfig()
    
    deinit {
        print("CropViewController deinit.")
    }
    
    init(image: UIImage, config: MantisConfig = MantisConfig(), mode: CropViewControllerMode = .normal) {
        self.image = image
        self.config = config
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func initLayout() {
        initToolarAutoLayout()
        initCropViewAutoLayout()
        updateLayout()
        
        uiConstraints = [cropViewTopConstraint, cropViewLandscapeBottomConstraint, cropViewPortraitBottomConstraint, cropViewLandscapeLeftLeftConstraint, cropViewLandscapeRightLeftConstraint, cropViewPortraitLeftConstraint, cropViewLandscapeLeftRightConstraint, cropViewLandscapeRightRightConstraint, cropViewPortaitRightConstraint, toolbarWidthConstraint, toolbarHeightConstraint, toolbarTopConstraint, toolbarPortraitBottomConstraint, toolbarLandscapeBottomConstraint, toolbarLeftConstraint, toolbarRightConstraint]
    }
    
    fileprivate func createCropToolbar() {
        guard cropToolbar == nil else {
            return
        }
        
        cropToolbar = CropToolbar(frame: CGRect.zero)
        cropToolbar?.backgroundColor = .black
        
        cropToolbar?.selectedCancel = {[weak self] in self?.handleCancel() }
        cropToolbar?.selectedRotate = {[weak self] in self?.handleRotate() }
        cropToolbar?.selectedReset = {[weak self] in self?.handleReset() }
        cropToolbar?.selectedSetRatio = {[weak self] in self?.handleSetRatio() }
        cropToolbar?.selectedCrop = {[weak self] in self?.handleCrop() }
        
        if mode == .normal {
            cropToolbar?.createToolbarUI()
        } else {
            cropToolbar?.createToolbarUI(mode: .simple)
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        createCropToolbar()
        createCropView()
        initLayout()
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initialLayout == false {
            initialLayout = true
            cropView?.adaptForCropBox()
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
        cropView?.prepareForDeviceRotation()
    }    
    
    @objc func rotated() {
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        
        guard statusBarOrientation != .unknown else { return }
        guard statusBarOrientation != orientation else { return }
        
        orientation = statusBarOrientation
        
        if UIDevice.current.userInterfaceIdiom == .phone
            && statusBarOrientation == .portraitUpsideDown {
            return
        }
        
        updateLayout()
        view.layoutIfNeeded()
        
        // When it is embedded in a container, the timing of viewDidLayoutSubviews
        // is different with the normal mode.
        // So delay the execution to make sure handleRotate runs after the final
        // viewDidLayoutSubviews
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.cropView?.handleRotate()
        }
        
    }
    
    private func createCropView() {
        guard let image = image else { return }
        
        cropView = CropView(image: image, viewModel: CropViewModel())
        cropView?.delegate = self
        cropView?.clipsToBounds = true
    }
    
    private func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleSetRatio() {
        guard let cropView = cropView else { return }
        
        if cropView.aspectRatioLockEnabled {
            cropView.aspectRatioLockEnabled = false
            cropToolbar?.setRatioButton?.tintColor = .white
            return
        }
        
        guard let image = image else { return }
        
        func didSet(fixedRatio ratio: Double) {
            cropToolbar?.setRatioButton?.tintColor = nil
            cropView.aspectRatioLockEnabled = true
            cropView.viewModel.aspectRatio = CGFloat(ratio)
            
            UIView.animate(withDuration: 0.5) {
                cropView.setFixedRatioCropBox()
            }            
        }
        
        let type: RatioType = cropView.getRatioType(byImageIsOriginalisHorizontal: image.isHorizontal())
        
        let ratio = cropView.getImageRatioH()
        
        ratioPresenter = RatioPresenter(type: type, originalRatioH: ratio, customRatios: config.getCustomRatioItems())
        ratioPresenter?.didGetRatio = { ratio in
            didSet(fixedRatio: ratio)
        }
        ratioPresenter?.present(by: self, in: cropToolbar!.setRatioButton!)
    }

    private func handleReset() {
        cropView?.reset()
    }
    
    private func handleRotate() {
        cropView?.counterclockwiseRotate90()
    }
    
    private func handleCrop() {
        guard let image = cropView?.crop() else {
            return
        }
        
        dismiss(animated: true) {
            self.delegate?.didGetCroppedImage(image: image)
        }
    }
}

// Auto layout
extension CropViewController {
    fileprivate func initCropViewAutoLayout() {
        guard let cropView = cropView, let cropToolbar = cropToolbar else { return }
        
        view.addSubview(cropView)
        
        cropView.translatesAutoresizingMaskIntoConstraints = false
        
        cropViewTopConstraint = cropView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        cropViewLandscapeBottomConstraint = cropView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        cropViewLandscapeLeftLeftConstraint = cropView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor)
        cropViewLandscapeLeftRightConstraint = cropView.rightAnchor.constraint(equalTo: cropToolbar.leftAnchor)
        
        cropViewLandscapeRightLeftConstraint = cropView.leftAnchor.constraint(equalTo: cropToolbar.rightAnchor)
        cropViewLandscapeRightRightConstraint = cropView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        
        cropViewPortraitBottomConstraint = cropView.bottomAnchor.constraint(equalTo: cropToolbar.topAnchor)
        cropViewPortraitLeftConstraint = cropView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor)
        cropViewPortaitRightConstraint = cropView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
    }
    
    fileprivate func initToolarAutoLayout() {
        guard let cropToolbar = cropToolbar else { return }
        
        view.addSubview(cropToolbar)
        cropToolbar.translatesAutoresizingMaskIntoConstraints = false
        
        toolbarWidthConstraint = cropToolbar.widthAnchor.constraint(equalToConstant: cropToolbar.recommendWidth)
        toolbarHeightConstraint = cropToolbar.heightAnchor.constraint(equalToConstant: cropToolbar.recommendHeight)

        toolbarTopConstraint = cropToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40)
        toolbarPortraitBottomConstraint = cropToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        toolbarLandscapeBottomConstraint = cropToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        toolbarLeftConstraint = cropToolbar.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor)
        toolbarRightConstraint = cropToolbar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
    }
    
    fileprivate func updateLayout() {
        uiConstraints.forEach{ $0?.isActive = false }
        
        cropToolbar?.checkOrientation()
        
        if UIApplication.shared.statusBarOrientation.isPortrait {
            toolbarHeightConstraint?.isActive = true
            toolbarLeftConstraint?.isActive = true
            toolbarRightConstraint?.isActive = true
            toolbarPortraitBottomConstraint?.isActive = true
            
            cropViewTopConstraint?.isActive = true
            cropViewPortraitBottomConstraint?.isActive = true
            cropViewPortraitLeftConstraint?.isActive = true
            cropViewPortaitRightConstraint?.isActive = true
        } else if UIApplication.shared.statusBarOrientation.isLandscape {
            toolbarWidthConstraint?.isActive = true
            toolbarTopConstraint?.isActive = true
            toolbarLandscapeBottomConstraint?.isActive = true
            
            cropViewTopConstraint?.isActive = true
            cropViewLandscapeBottomConstraint?.isActive = true
            
            if UIApplication.shared.statusBarOrientation == .landscapeLeft {
                toolbarRightConstraint?.isActive = true
                cropViewLandscapeLeftLeftConstraint?.isActive = true
                cropViewLandscapeLeftRightConstraint?.isActive = true
            } else {
                toolbarLeftConstraint?.isActive = true
                cropViewLandscapeRightLeftConstraint?.isActive = true
                cropViewLandscapeRightRightConstraint?.isActive = true
            }
        }
    }
}

extension CropViewController: CropViewDelegate {
    func cropViewDidBecomeResettable(_ cropView: CropView) {
        cropToolbar?.resetButton?.isHidden = false
    }
    
    func cropViewDidBecomeNonResettable(_ cropView: CropView) {
        cropToolbar?.resetButton?.isHidden = true
    }
}

// API
extension CropViewController {
    public func crop() {
        if let image = cropView?.crop() {
            delegate?.didGetCroppedImage(image: image)
        }        
    }
}
