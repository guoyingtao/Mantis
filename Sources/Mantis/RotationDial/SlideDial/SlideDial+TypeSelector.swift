//
//  SlideDial+TypeSelector.swift
//  Mantis
//
//  Extracted from SlideDial.swift — type selector mode logic
//

import UIKit

// MARK: - Type Selector Mode (Button Creation, Layout, Interaction)
extension SlideDial {
    /// The fixed order of all adjustment types
    static let allAdjustmentTypes: [RotationAdjustmentType] = [.straighten, .verticalSkew, .horizontalSkew]
    
    func createTypeButtons() {
        // Remove old buttons if re-laying out
        typeButtons.values.forEach { $0.removeFromSuperview() }
        typeButtons.removeAll()
        
        for type in Self.allAdjustmentTypes {
            let button = SlideDialTypeButton(type: type, config: config)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(typeButtonTapped(_:)))
            button.addGestureRecognizer(tap)
            button.isUserInteractionEnabled = true
            
            addSubview(button)
            typeButtons[type] = button
        }
        
        // Set initial selection and layout
        typeButtons[.straighten]?.setSelected(true)
        layoutTypeButtons(animated: false)
    }
    
    /// Positions buttons in a fixed row, sliding the group horizontally so the
    /// selected button is centered above the ruler pointer (matching Apple Photos).
    func layoutTypeButtons(animated: Bool) {
        let buttonSize = config.typeButtonSize
        let spacing = config.typeButtonSpacing
        let topPadding: CGFloat = 16
        let buttonY: CGFloat = topPadding
        let centerX = frame.width / 2
        
        // Index of the selected type in the fixed order
        let selectedIndex = Self.allAdjustmentTypes.firstIndex(of: viewModel.currentAdjustmentType) ?? 0
                
        // Position of the selected button's center within the group (relative to group leading edge)
        let selectedCenterInGroup = CGFloat(selectedIndex) * (buttonSize + spacing) + buttonSize / 2
        
        // Offset so that the selected button's center aligns with the view's centerX
        let groupOriginX = centerX - selectedCenterInGroup
        
        let applyLayout = {
            for (idx, type) in Self.allAdjustmentTypes.enumerated() {
                let originX = groupOriginX + CGFloat(idx) * (buttonSize + spacing)
                self.typeButtons[type]?.frame = CGRect(
                    x: originX,
                    y: buttonY,
                    width: buttonSize,
                    height: buttonSize
                )
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                applyLayout()
            }
        } else {
            applyLayout()
        }
    }
    
    @objc func typeButtonTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedButton = gesture.view as? SlideDialTypeButton else { return }
        let newType = tappedButton.adjustmentType
        
        if newType == viewModel.currentAdjustmentType {
            // Tapping the already selected button resets that type's value
            viewModel.storeAngle(0, for: newType)
            viewModel.rotationAngle = Angle(degrees: 0)
            slideRuler?.reset()
            tappedButton.setValue(0)
            didFinishRotation()
            return
        }
        
        // Save current angle before switching
        viewModel.storeAngle(viewModel.rotationAngle.degrees, for: viewModel.currentAdjustmentType)
        
        // Update button selection states
        typeButtons[viewModel.currentAdjustmentType]?.setSelected(false)
        tappedButton.setSelected(true)
        
        // Switch type in viewModel
        viewModel.currentAdjustmentType = newType
        
        // Animate the selected button to center
        layoutTypeButtons(animated: true)
        
        // Restore the stored angle for the new type
        let storedAngle = viewModel.storedAngle(for: newType)
        let newLimit = config.limitation(for: newType)
        
        // Reset ruler and set to new value
        slideRuler?.reset()
        if abs(storedAngle) > 0.5 {
            slideRuler?.setOffsetRatio(storedAngle / newLimit)
        }
        
        // Update viewModel without triggering external callback
        updateViewModelAngleSilently(degrees: storedAngle)
        
        // Notify CropView about type switch
        didSwitchAdjustmentType?(newType)
    }
    
    func updateSelectedTypeButton(with degrees: CGFloat) {
        let currentType = viewModel.currentAdjustmentType
        typeButtons[currentType]?.setValue(degrees)
        viewModel.storeAngle(degrees, for: currentType)
    }
    
    func resetAllTypeButtons() {
        for (_, button) in typeButtons {
            button.setValue(0)
            button.setSelected(false)
        }
        typeButtons[.straighten]?.setSelected(true)
        layoutTypeButtons(animated: false)
    }
    
    /// Update type button values from external source (e.g. when CropView restores state)
    func updateTypeButtonValues(straighten: CGFloat, horizontal: CGFloat, vertical: CGFloat) {
        typeButtons[.straighten]?.setValue(straighten)
        typeButtons[.horizontalSkew]?.setValue(horizontal)
        typeButtons[.verticalSkew]?.setValue(vertical)
    }
    
    /// Get the currently selected adjustment type
    func getCurrentAdjustmentType() -> RotationAdjustmentType {
        viewModel.currentAdjustmentType
    }
    
    /// Called by CropView after a flip to sync the SlideDial's stored straighten value
    /// without disturbing the ruler when a skew tab is active.
    func syncStraightenValue(_ degrees: CGFloat) {
        guard case .withTypeSelector = config.mode else { return }
        
        viewModel.storeAngle(degrees, for: .straighten)
        typeButtons[.straighten]?.setValue(degrees)
        
        if viewModel.currentAdjustmentType == .straighten {
            let limit = config.limitation(for: .straighten)
            updateViewModelAngleSilently(degrees: degrees)
            
            slideRuler?.reset()
            if abs(degrees) > 0.5 {
                slideRuler?.setOffsetRatio(degrees / limit)
            }
        }
    }
    
    /// Called by CropView after a 90° rotation to sync the SlideDial's stored skew values
    /// with the swapped values in CropView's viewModel.
    func syncSkewValues(horizontal: CGFloat, vertical: CGFloat) {
        guard case .withTypeSelector = config.mode else { return }
        
        // Update stored angles
        viewModel.storeAngle(horizontal, for: .horizontalSkew)
        viewModel.storeAngle(vertical, for: .verticalSkew)
        
        // Update button displays
        typeButtons[.horizontalSkew]?.setValue(horizontal)
        typeButtons[.verticalSkew]?.setValue(vertical)
        
        // If the currently active type is a skew type, update ruler position
        let currentType = viewModel.currentAdjustmentType
        if currentType == .horizontalSkew || currentType == .verticalSkew {
            let newAngle = currentType == .horizontalSkew ? horizontal : vertical
            let limit = config.limitation(for: currentType)
            
            updateViewModelAngleSilently(degrees: newAngle)
            
            slideRuler?.reset()
            if abs(newAngle) > 0.5 {
                slideRuler?.setOffsetRatio(newAngle / limit)
            }
        }
    }
    
    /// Updates the viewModel's rotation angle without triggering the external
    /// `didUpdateRotationValue` callback. Used when restoring stored angles
    /// during type switches or external sync operations.
    func updateViewModelAngleSilently(degrees: CGFloat) {
        viewModel.didSetRotationAngle = { _ in }
        viewModel.rotationAngle = Angle(degrees: degrees)
        viewModel.didSetRotationAngle = { [weak self] angle in
            self?.handleRotation(by: angle)
        }
    }
}

// MARK: - Auto-hide Inactive Buttons

extension SlideDial {
    func startHideTimerIfNeeded() {
        guard case .withTypeSelector = config.mode else { return }
        guard hideInactiveButtonsTimer == nil else { return }
        
        let timer = Timer(timeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.hideInactiveButtons()
        }
        RunLoop.main.add(timer, forMode: .common)
        hideInactiveButtonsTimer = timer
    }
    
    func hideInactiveButtons() {
        guard !inactiveButtonsHidden else { return }
        inactiveButtonsHidden = true
        let activeType = viewModel.currentAdjustmentType
        UIView.animate(withDuration: 0.25) {
            for (type, button) in self.typeButtons where type != activeType {
                button.alpha = 0
            }
        }
    }
    
    func showInactiveButtons() {
        hideInactiveButtonsTimer?.invalidate()
        hideInactiveButtonsTimer = nil
        guard inactiveButtonsHidden else { return }
        inactiveButtonsHidden = false
        UIView.animate(withDuration: 0.25) {
            for (_, button) in self.typeButtons {
                button.alpha = 1
            }
        }
    }
}
