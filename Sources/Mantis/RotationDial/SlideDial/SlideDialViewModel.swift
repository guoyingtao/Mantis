//
//  SlideDialViewModel.swift
//  Mantis
//
//  Created by Yingtao Guo on 6/19/23.
//

import Foundation

final class SlideDialViewModel {
    var didSetRotationAngle: (Angle) -> Void = { _ in }
    
    /// Called when the selected adjustment type changes (only used in withTypeSelector mode)
    var didChangeAdjustmentType: ((RotationAdjustmentType) -> Void)?
    
    var rotationAngle = Angle(degrees: 0) {
        didSet {
            didSetRotationAngle(rotationAngle)
        }
    }
    
    // MARK: - Multi-type support (withTypeSelector mode)
    
    var currentAdjustmentType: RotationAdjustmentType = .straighten
    
    /// Stored angles for each adjustment type
    private var storedAngles: [RotationAdjustmentType: CGFloat] = [
        .straighten: 0,
        .horizontalSkew: 0,
        .verticalSkew: 0
    ]
    
    func storedAngle(for type: RotationAdjustmentType) -> CGFloat {
        storedAngles[type] ?? 0
    }
    
    func storeAngle(_ degrees: CGFloat, for type: RotationAdjustmentType) {
        storedAngles[type] = degrees
    }
        
    func reset() {
        rotationAngle = Angle(degrees: 0)
    }
    
    func resetAll() {
        storedAngles = [
            .straighten: 0,
            .horizontalSkew: 0,
            .verticalSkew: 0
        ]
        currentAdjustmentType = .straighten
        rotationAngle = Angle(degrees: 0)
    }
}
