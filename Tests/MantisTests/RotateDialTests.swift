//
//  RotateDialTests.swift
//  MantisTests
//
//  Created by yingtguo on 2/3/23.
//

import XCTest
@testable import Mantis

final class RotateDialTests: XCTestCase {
    
    var dial: RotationDial!
    var dialPlate: RotationDialPlate!
    var viewModel: RotationDialViewModel!

    override func setUpWithError() throws {
        let config = RotationDialConfig()
        setup(with: config)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    private func setup(with config: RotationDialConfig) {
        viewModel = RotationDialViewModel()
        dialPlate = RotationDialPlate(frame: .zero, config: config)
        dial = RotationDial(frame: .zero,
                            config: config,
                            viewModel: viewModel,
                            dialPlate: dialPlate)
        dial.setupUI(withAllowableFrame: .zero)
    }
    
    func testRotateDialPlate() {
        // Test valid plus rotation
        let dialConfig = RotationDialConfig()
        setup(with: dialConfig)
        
        var dialPlateTransform = dialPlate.transform
        var angle = Angle(degrees: 40)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        
        // Test invalid plus rotation
        setup(with: dialConfig)
        
        dialPlateTransform = dialPlate.transform
        angle = Angle(degrees: 50)
        XCTAssertFalse(dial.updateRotationValue(by: angle))
        XCTAssertNotEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: Angle(degrees: 0).radians))
        
        // Test valid minus rotation
        setup(with: dialConfig)
        
        dialPlateTransform = dialPlate.transform
        angle = Angle(degrees: -40)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        
        // Test invalid minus rotation
        setup(with: dialConfig)
        
        dialPlateTransform = dialPlate.transform
        angle = Angle(degrees: -50)
        XCTAssertFalse(dial.updateRotationValue(by: angle))
        XCTAssertNotEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: Angle(degrees: 0).radians))
    }
    
    func testReset() {
        let dialConfig = RotationDialConfig()
        setup(with: dialConfig)
        
        let dialPlateTransform = dialPlate.transform
        let angle = Angle(degrees: 40)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))

        dial.reset()
        XCTAssertEqual(viewModel.rotationAngle.degrees, 0)
        XCTAssertEqual(dial.transform, .identity)
    }

    func testAccessibilityIncrementAndDecrement() {
        setup(with: RotationDialConfig())
        
        var updatedDegrees: [CGFloat] = []
        var finishCount = 0
        dial.didUpdateRotationValue = { updatedDegrees.append($0.degrees) }
        dial.didFinishRotation = { finishCount += 1 }
        
        dial.accessibilityIncrement()
        dial.accessibilityIncrement()
        XCTAssertEqual(dial.getRotationAngle().degrees, 2, accuracy: 1e-3)
        XCTAssertEqual(dial.accessibilityValue, "2 degrees")
        
        dial.accessibilityDecrement()
        dial.accessibilityDecrement()
        dial.accessibilityDecrement()
        XCTAssertEqual(dial.getRotationAngle().degrees, -1, accuracy: 1e-3)
        XCTAssertEqual(dial.accessibilityValue, "-1 degree")
        XCTAssertEqual(updatedDegrees.count, 5)
        XCTAssertEqual(updatedDegrees.last ?? 0, -1, accuracy: 1e-3)
        XCTAssertEqual(finishCount, 5)
    }
    
    func testAccessibilityAdjustmentStopsAtAngleLimit() {
        for sign: CGFloat in [1, -1] {
            setup(with: RotationDialConfig())
            XCTAssertTrue(dial.updateRotationValue(by: Angle(degrees: 44.5 * sign)))
            
            var updatedDegrees: [CGFloat] = []
            var finishCount = 0
            dial.didUpdateRotationValue = { updatedDegrees.append($0.degrees) }
            dial.didFinishRotation = { finishCount += 1 }
            let stepOutward = sign > 0 ? dial.accessibilityIncrement : dial.accessibilityDecrement
            
            // The last half step lands on the limit and is reported
            stepOutward()
            XCTAssertEqual(dial.getRotationAngle().degrees, 45 * sign, accuracy: 1e-3, "\(sign)")
            XCTAssertEqual(updatedDegrees.count, 1, "\(sign)")
            XCTAssertEqual(updatedDegrees.last ?? 0, 45 * sign, accuracy: 1e-3, "\(sign)")
            XCTAssertEqual(finishCount, 1, "\(sign)")
            
            // Already at the limit: nothing changes, so nothing is reported
            stepOutward()
            XCTAssertEqual(dial.getRotationAngle().degrees, 45 * sign, accuracy: 1e-3, "\(sign)")
            XCTAssertEqual(updatedDegrees.count, 1, "\(sign)")
            XCTAssertEqual(finishCount, 1, "\(sign)")
        }
    }
    
}
