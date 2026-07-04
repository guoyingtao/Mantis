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
        
        if config.cropToolbarConfig.mode == .embedded {
            // In embedded mode the crop view is added as a subview of a container
            // that already manages its own safe area. Pinning to the safe area
            // layout guide here would apply the inherited insets a second time,
            // pushing the content down and clipping the bottom (notably on iOS 26,
            // which changed how safe area insets propagate to child views).
            // Pin directly to view edges and let the embedding parent own safe area.
            stackView?.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            stackView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            stackView?.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            stackView?.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        } else {
            stackView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            stackView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            stackView?.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
            stackView?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        }
        
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), config.showAttachedCropToolbar {
            // Allow the crop view's mask to extend visually behind the toolbar
            cropView.clipsToBounds = false
            cropStackView?.clipsToBounds = false
        }
        #endif
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
        
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), config.showAttachedCropToolbar {
            // Ensure the toolbar renders above the crop view's mask overflow
            stackView?.bringSubviewToFront(cropToolbar)
        }
        #endif
    }
            
    func updateLayout() {
        setStackViewAxis()
        cropToolbar.respondToOrientationChange()
        changeStackViewOrder()
    }
}
