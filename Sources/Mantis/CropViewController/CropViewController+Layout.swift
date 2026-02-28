//
//  CropViewController+Layout.swift
//  Mantis
//
//  Extracted from CropViewController.swift
//

import UIKit

// MARK: - Auto Layout
extension CropViewController {
    func initLayout() {
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
        
        if #available(iOS 26.0, *), config.showAttachedCropToolbar {
            // Allow the crop view's mask to extend visually behind the toolbar
            cropView.clipsToBounds = false
            cropStackView?.clipsToBounds = false
        }
    }
    
    func setStackViewAxis() {
        if Orientation.treatAsPortrait {
            stackView?.axis = .vertical
        } else if Orientation.isLandscape {
            stackView?.axis = .horizontal
        }
    }
    
    func changeStackViewOrder() {
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
        
        if #available(iOS 26.0, *), config.showAttachedCropToolbar {
            // Ensure the toolbar renders above the crop view's mask overflow
            stackView?.bringSubviewToFront(cropToolbar)
        }
    }
            
    func updateLayout() {
        setStackViewAxis()
        cropToolbar.respondToOrientationChange()
        changeStackViewOrder()
    }
}
