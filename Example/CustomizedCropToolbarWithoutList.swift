//
//  CustomizedCropToolbarWithoutList.swift
//  MantisExample
//
//  Created by designerdrug on 10/01/20.
//  Copyright © 2020 Echo. All rights reserved.
//

import UIKit
import Mantis

class CustomizedCropToolbarWithoutList: UIView, CropToolbarProtocol {
    var iconProvider: CropToolbarIconProvider?
    weak var delegate: CropToolbarDelegate?
    
    var config = CropToolbarConfig()
    
    private var fixedRatioSettingButton: UIButton?
    private var portraitRatioButton: UIButton?
    private var landscapeRatioButton: UIButton?
    private var cropButton: UIButton?
    private var cancelButton: UIButton?
    private var stackView: UIStackView?
        
    var custom: ((Double) -> Void)?
    
    func createToolbarUI(config: CropToolbarConfig) {
        self.config = config
        
        backgroundColor = .darkGray
        
        cropButton = createOptionButton(withTitle: "Crop", andAction: #selector(crop))
        cancelButton = createOptionButton(withTitle: "Cancel", andAction: #selector(cancel))
        portraitRatioButton = createOptionButton(withTitle: "9:16", andAction: #selector(setPortraitRatio))
        landscapeRatioButton = createOptionButton(withTitle: "16:9", andAction: #selector(setLandscapeRatio))

        stackView = UIStackView()
        addSubview(stackView!)
        
        stackView?.translatesAutoresizingMaskIntoConstraints = false
        stackView?.alignment = .center
        stackView?.distribution = .fillEqually
        
        stackView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        stackView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stackView?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stackView?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        stackView?.addArrangedSubview(cancelButton!)
        stackView?.addArrangedSubview(portraitRatioButton!)
        stackView?.addArrangedSubview(landscapeRatioButton!)
        stackView?.addArrangedSubview(cropButton!)
    }
    
    public func handleFixedRatioSetted(ratio: Double) {
        switch ratio {
        case 9 / 16:
            portraitRatioButton?.setTitleColor(.blue, for: .normal)
            landscapeRatioButton?.setTitleColor(.white, for: .normal)
        case 16 / 9:
            landscapeRatioButton?.setTitleColor(.blue, for: .normal)
            portraitRatioButton?.setTitleColor(.white, for: .normal)
        default:
            landscapeRatioButton?.setTitleColor(.white, for: .normal)
            portraitRatioButton?.setTitleColor(.white, for: .normal)
        }
        
    }
    
    public func handleFixedRatioUnSetted() {
    }
    
    public override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        
        if Orientation.isPortrait {
            return CGSize(width: superSize.width, height: config.heightForVerticalOrientation)
        } else {
            return CGSize(width: config.widthForHorizontalOrientation, height: superSize.height)
        }
    }

    func adjustLayoutWhenOrientationChange() {
        if Orientation.isPortrait {
            stackView?.axis = .horizontal
        } else {
            stackView?.axis = .vertical
        }
    }
    
    @objc private func crop() {
        delegate?.didSelectCrop(self)
    }
    
    @objc private func cancel() {
        delegate?.didSelectCancel(self)
    }
    
    @objc private func setPortraitRatio() {
        delegate?.didSelectRatio(self, ratio: 9 / 16)
    }
    
    @objc private func setLandscapeRatio() {
        delegate?.didSelectRatio(self, ratio: 16 / 9)
    }
    
    private func createOptionButton(withTitle title: String?, andAction action: Selector) -> UIButton {
        let buttonColor = UIColor.white
        let buttonFontSize: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ?
            config.optionButtonFontSizeForPad :
            config.optionButtonFontSize
        
        let buttonFont = UIFont.systemFont(ofSize: buttonFontSize)
        
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.titleLabel?.font = buttonFont
        
        if let title = title {
            button.setTitle(title, for: .normal)
            button.setTitleColor(buttonColor, for: .normal)
        }
        
        button.addTarget(self, action: action, for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        
        return button
    }
}
