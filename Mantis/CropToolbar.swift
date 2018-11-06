//
//  CropToolbar.swift
//  Mantis
//
//  Created by Echo on 11/6/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropToolbar: UIView {
    
    var selectedCancel = {}
    var selectedCrop = {}
    var selectedRotate = {}
    var selectedReset = {}
    var selectedSetRatio = {}
    
    var cancelButton: UIButton?
    var setRatioButton: UIButton?
    var resetButton: UIButton?
    var anticlockRotateButton: UIButton?
    var cropButton: UIButton?
    
    private var optionButtonStackView: UIStackView?
    
    private func createOptionButton(withTitle title: String?, andAction action: Selector) -> UIButton {
        let buttonRect = CGRect.zero
        let buttonColor = UIColor.white
        let buttonFont = UIFont.systemFont(ofSize: 20)
        
        let button = UIButton(frame: buttonRect)
        button.titleLabel?.font = buttonFont
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        
        if let title = title {
            button.setTitle(title, for: .normal)
            button.setTitleColor(buttonColor, for: .normal)
        }
        
        button.addTarget(self, action: action, for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        
        return button
    }
    
    func createToolbarUI() {
        cancelButton = createOptionButton(withTitle: "Cancel", andAction: #selector(cancel))
        
        anticlockRotateButton = createOptionButton(withTitle: nil, andAction: #selector(rotate))
        anticlockRotateButton?.setImage(ToolBarButtonImageBuilder.rotateCCWImage(), for: .normal)
        
        resetButton = createOptionButton(withTitle: "Reset", andAction: #selector(reset))
        
        setRatioButton = createOptionButton(withTitle: nil, andAction: #selector(setRatio))
        setRatioButton?.setImage(ToolBarButtonImageBuilder.clampImage(), for: .normal)
        
        cropButton = createOptionButton(withTitle: "Done", andAction: #selector(crop))
        
        optionButtonStackView = UIStackView()
        addSubview(optionButtonStackView!)
        
        optionButtonStackView?.translatesAutoresizingMaskIntoConstraints = false
        optionButtonStackView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionButtonStackView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        optionButtonStackView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        optionButtonStackView?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        optionButtonStackView?.distribution = .equalCentering
        optionButtonStackView?.addArrangedSubview(cancelButton!)
        optionButtonStackView?.addArrangedSubview(anticlockRotateButton!)
        optionButtonStackView?.addArrangedSubview(resetButton!)
        optionButtonStackView?.addArrangedSubview(setRatioButton!)
        optionButtonStackView?.addArrangedSubview(cropButton!)
    }
    
    func checkOrientation() {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            optionButtonStackView?.axis = .horizontal
        } else {
            optionButtonStackView?.axis = .vertical
        }
    }
    
    @objc private func cancel() {
        selectedCancel()
    }
    
    @objc private func setRatio() {
        selectedSetRatio()
    }
    
    @objc private func reset(_ sender: Any) {
        selectedReset()
    }
    
    @objc private func rotate(_ sender: Any) {
        selectedRotate()
    }
    
    @objc private func crop(_ sender: Any) {
        selectedCrop()
    }
}
