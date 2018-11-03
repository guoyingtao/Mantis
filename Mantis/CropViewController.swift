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
    
    var cancelBarButtonItem: UIBarButtonItem?
    var setRatioBarButtonItem: UIBarButtonItem?
    var resetBarButtonItem: UIBarButtonItem?
    var anticlockRorateBarButtonItem: UIBarButtonItem?
    var cropBarButtonItem: UIBarButtonItem?
    
    var ratioPresenter: RatioPresenter?
    
    var cropView: CropView?
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
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        navigationController?.isToolbarHidden = false
        
        if mode == .normal {
            createToolbarUI()
        } else {
            createBottomOpertions()
        }
        
        guard let image = image else { return }
        
        cropView = CropView(image: image)
        guard let cropView = cropView else { return }
        
        cropView.delegate = self
        cropView.clipsToBounds = true
        view.addSubview(cropView)
        
        cropView.translatesAutoresizingMaskIntoConstraints = false
        cropView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        cropView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80).isActive = true
        cropView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        cropView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cropView?.adaptForCropBox()
    }
    
    private func createCancleButton() {
        cancelBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
    }
    
    private func createSetRatioButton() {
        setRatioBarButtonItem = UIBarButtonItem(title: "Set Ratio", style: .plain, target: self, action: #selector(setRatio))
    }
    
    private func createResetButton() {
        resetBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(reset))
    }
    
    private func createRotateButton() {
        anticlockRorateBarButtonItem = UIBarButtonItem(title: "Rotate", style: .plain, target: self, action: #selector(rotate))
    }
    
    private func createCropButton() {
        cropBarButtonItem = UIBarButtonItem(title: "Crop", style: .plain, target: self, action: #selector(crop))
    }
    
    private func createFlexibleSpace() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    }
    
    private func createToolbarUI() {        
        createCancleButton()
        createRotateButton()
        createResetButton()
        createSetRatioButton()
        createCropButton()
        
        toolbarItems = [cancelBarButtonItem!, createFlexibleSpace(), anticlockRorateBarButtonItem!, createFlexibleSpace(), resetBarButtonItem!, createFlexibleSpace(), setRatioBarButtonItem!, createFlexibleSpace(), cropBarButtonItem!]
    }
    
    private func createBottomOpertions() {
        createRotateButton()
        createResetButton()
        createSetRatioButton()
        
        let toolbar = UIToolbar(frame: CGRect.zero)
        toolbar.items = [anticlockRorateBarButtonItem!, createFlexibleSpace(), resetBarButtonItem!, createFlexibleSpace(), setRatioBarButtonItem!]
    }
    
    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func setRatio() {
        guard let image = image else { return }
        let type: RatioType = image.isHoritontal() ? .horizontal : .vertical
        let ratio = Double(image.ratio())
        ratioPresenter = RatioPresenter(type: type, originalRatio: ratio)
        ratioPresenter?.didGetRatio = { ratio in print("ratio is \(ratio)") }
        ratioPresenter?.present(in: self)
    }

    @objc private func reset(_ sender: Any) {
        cropView?.reset()
    }
    
    @objc private func rotate(_ sender: Any) {
        cropView?.anticlockwiseRotate90()
    }
    
    @objc private func crop(_ sender: Any) {
        guard let image = cropView?.crop() else {
            return
        }
        
        dismiss(animated: true) {
            self.delegate?.didGetCroppedImage(image: image)
        }
    }
}

extension CropViewController: CropViewDelegate {
    func cropViewDidBecomeResettable(_ cropView: CropView) {
        
    }
    
    func cropViewDidBecomeNonResettable(_ cropView: CropView) {
        
    }
}
