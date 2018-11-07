//
//  CropViewController.swift
//  Mantis
//
//  Created by Echo on 10/30/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

public protocol CropViewControllerProtocal {
    func didGetCroppedImage(image: UIImage)
}

public enum CropViewControllerMode {
    case embedded
    case normal
}

public class CropViewController: UIViewController {
    
    var delegate: CropViewControllerProtocal?
    
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
    
    var image: UIImage? {
        didSet {
            cropView?.adaptForCropBox()
        }
    }
    
    var mode: CropViewControllerMode = .normal
    
    init(image: UIImage) {
        self.image = image
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
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        navigationController?.isToolbarHidden = true
        
        cropToolbar = CropToolbar(frame: CGRect.zero)
        cropToolbar?.selectedCancel = {[weak self] in self?.cancel() }
        cropToolbar?.selectedRotate = {[weak self] in self?.rotate() }
        cropToolbar?.selectedReset = {[weak self] in self?.reset() }
        cropToolbar?.selectedSetRatio = {[weak self] in self?.setRatio() }
        cropToolbar?.selectedCrop = {[weak self] in self?.crop() }
        
        if mode == .normal {
            cropToolbar?.createToolbarUI()
        } else {
            cropToolbar?.createBottomOpertions()
        }
        
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
        
        guard statusBarOrientation != .unknown else {
            return
        }
        
        guard statusBarOrientation != orientation else {
            return
        }
        
        orientation = statusBarOrientation
        
        if UIDevice.current.userInterfaceIdiom == .phone
            && statusBarOrientation == .portraitUpsideDown {
            return
        }
        
        updateLayout()
        view.layoutIfNeeded()
        cropView?.handleRotate()
    }
        
    private func createCropView() {
        guard let image = image else { return }
        
        cropView = CropView(image: image)
        guard let cropView = cropView else { return }
        
//        cropView.layer.borderWidth = 1
//        cropView.layer.borderColor = UIColor.green.cgColor
        
        cropView.delegate = self
        cropView.clipsToBounds = true
    }
    
    private func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func setRatio() {
        guard let cropView = cropView else { return }
        
        if cropView.aspectRatioLockEnabled {
            cropView.aspectRatioLockEnabled = false
            cropToolbar?.setRatioButton?.setTitleColor(.white, for: .normal)
            return
        }
        
        guard let image = image else { return }
        
        func didSet(fixedRatio ratio: Double) {
            cropToolbar?.setRatioButton?.setTitleColor(.blue, for: .normal)
            cropView.aspectRatioLockEnabled = true
            cropView.imageStatus.aspectRatio = CGFloat(ratio)
            
            UIView.animate(withDuration: 0.5) {
                cropView.setFixedRatioCropBox()
            }            
        }
        
        let type: RatioType = image.isHoritontal() ? .horizontal : .vertical
        let ratio = Double(image.ratio())
        ratioPresenter = RatioPresenter(type: type, originalRatio: ratio)
        ratioPresenter?.didGetRatio = { ratio in
            didSet(fixedRatio: ratio)
        }
        ratioPresenter?.present(by: self, in: cropToolbar!.setRatioButton!)
    }

    private func reset() {
        cropView?.reset()
    }
    
    private func rotate() {
        cropView?.anticlockwiseRotate90()
    }
    
    private func crop() {
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
        
        if mode == .normal {
            toolbarWidthConstraint = cropToolbar.widthAnchor.constraint(equalToConstant: 80)
            toolbarHeightConstraint = cropToolbar.heightAnchor.constraint(equalToConstant: 44)
        } else {
            toolbarWidthConstraint = cropToolbar.widthAnchor.constraint(equalToConstant: 124)
            toolbarHeightConstraint = cropToolbar.heightAnchor.constraint(equalToConstant: 88)
        }
        
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
        
    }
    
    func cropViewDidBecomeNonResettable(_ cropView: CropView) {
        
    }
}

extension CropViewController {
    public func add(button: UIButton) {
        
    }
}
