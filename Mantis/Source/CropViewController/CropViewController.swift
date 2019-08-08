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
    
    public weak var delegate: CropViewControllerProtocal?
    
    private var orientation: UIInterfaceOrientation = .unknown
        
    private var ratioPresenter: RatioPresenter?
    private var cropView: CropView?
    private var cropToolbar: CropToolbar?
    private var stackView: UIStackView?
    
    private var initialLayout = false
    
    public var image: UIImage?
    public var mode: CropViewControllerMode = .normal
    public var config = Mantis.Config()
    
    deinit {
        print("CropViewController deinit.")
    }
    
    init(image: UIImage, config: Mantis.Config = Mantis.Config(), mode: CropViewControllerMode = .normal) {
        self.image = image
        self.config = config
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        updateLayout()
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initialLayout == false {
            initialLayout = true
            view.layoutIfNeeded()
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
    
    private func resetRatioButton() {
        cropView?.aspectRatioLockEnabled = false
        cropToolbar?.setRatioButton?.tintColor = .white
    }
    
    @objc private func handleSetRatio() {
        guard let cropView = cropView else { return }
        
        if cropView.aspectRatioLockEnabled {
            resetRatioButton()
            return
        }
        
        guard let image = image else { return }
        
        func setFixedRatio(_ ratio: Double) {
            cropToolbar?.setRatioButton?.tintColor = nil
            cropView.aspectRatioLockEnabled = true
            cropView.viewModel.aspectRatio = CGFloat(ratio)
            
            UIView.animate(withDuration: 0.5) {
                cropView.setFixedRatioCropBox()
            }            
        }
        
        let type: RatioType = cropView.getRatioType(byImageIsOriginalisHorizontal: image.isHorizontal())
        
        let ratio = cropView.getImageRatioH()
        
        let ratioManager = FixedRatioManager(type: type,
                                             originalRatioH: ratio,
                                             ratioOptions: config.ratioOptions,
                                             customRatios: config.getCustomRatioItems())
        
        guard ratioManager.ratios.count > 0 else { return }
        
        if ratioManager.ratios.count == 1 {
            let ratioItem = ratioManager.ratios[0]
            let ratioValue = (type == .horizontal) ? ratioItem.ratioH : ratioItem.ratioV
            setFixedRatio(ratioValue)
            return
        }
        
        ratioPresenter = RatioPresenter(type: type, originalRatioH: ratio, ratios: ratioManager.ratios)
        ratioPresenter?.didGetRatio = { ratio in
            setFixedRatio(ratio)
        }
        ratioPresenter?.present(by: self, in: cropToolbar!.setRatioButton!)
    }

    private func handleReset() {
        resetRatioButton()
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
    fileprivate func initLayout() {
        guard let cropView = cropView, let cropToolbar = cropToolbar else {
            return
        }
        
        stackView = UIStackView()
        view.addSubview(stackView!)
        
        stackView?.translatesAutoresizingMaskIntoConstraints = false
        cropToolbar.translatesAutoresizingMaskIntoConstraints = false
        cropView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        stackView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        stackView?.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        stackView?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    }
    
    fileprivate func setStackViewAxis() {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            stackView?.axis = .vertical
        } else if UIApplication.shared.statusBarOrientation.isLandscape {
            stackView?.axis = .horizontal
        }
    }
    
    fileprivate func changeStackViewOrder() {
        guard let cropView = cropView, let cropToolbar = cropToolbar else {
            return
        }
        
        stackView?.removeArrangedSubview(cropView)
        stackView?.removeArrangedSubview(cropToolbar)
        
        if UIApplication.shared.statusBarOrientation.isPortrait || UIApplication.shared.statusBarOrientation == .landscapeRight {
            stackView?.addArrangedSubview(cropView)
            stackView?.addArrangedSubview(cropToolbar)
        } else if UIApplication.shared.statusBarOrientation == .landscapeLeft {
            stackView?.addArrangedSubview(cropToolbar)
            stackView?.addArrangedSubview(cropView)
        }
    }

    fileprivate func updateLayout() {
        setStackViewAxis()
        cropToolbar?.checkOrientation()
        changeStackViewOrder()
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
