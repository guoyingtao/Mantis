//
//  DebounceButton.swift
//  Mantis
//
//  Created by Yingtao Guo on 11/6/24.
//

import UIKit

/// A custom UIButton subclass that prevents multiple rapid taps and provides debouncing functionality
class DebounceButton: UIButton {
    // Default debounce interval in seconds
    private var debounceInterval: TimeInterval = 0.5
    
    // Timestamp of the last tap
    private var lastTapTimestamp: TimeInterval = 0
    
    // Flag to track if a crop operation is in progress
    private var isProcessing: Bool = false
    
    // Closure to store the actual crop operation
    private var cropOperation: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    /// Sets up the initial button configuration
    private func setupButton() {
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    // MARK: - Public Methods
    
    /// Sets the minimum time interval between valid taps
    /// - Parameter interval: The time interval in seconds
    func setDebounceInterval(_ interval: TimeInterval) {
        debounceInterval = interval
    }
    
    /// Sets the crop operation to be performed when the button is tapped
    /// - Parameter operation: A closure containing the crop logic
    func setCropOperation(_ operation: @escaping () -> Void) {
        cropOperation = operation
    }
    
    // MARK: - Private Methods
    
    /// Handles the button tap event with debouncing logic
    @objc private func handleTap() {
        let currentTime = Date().timeIntervalSince1970
        
        // If a crop operation is already in progress, ignore the tap
        guard !isProcessing else {
            return
        }
        
        // Check if enough time has passed since the last tap
        if currentTime - lastTapTimestamp >= debounceInterval {
            lastTapTimestamp = currentTime
            isProcessing = true
            
            // Perform the crop operation
            performCropOperation()
        }
    }
    
    /// Executes the stored crop operation with proper state management
    private func performCropOperation() {
        guard let operation = cropOperation else {
            isProcessing = false
            return
        }
        
        // Disable the button while processing
        isEnabled = false
        
        // Execute the stored crop operation
        cropOperation?()
        
        // Simulate async operation completion
        // In real implementation, this should be called after the actual crop operation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // Re-enable the button and reset processing state
            self?.isEnabled = true
            self?.isProcessing = false
        }
    }
}
