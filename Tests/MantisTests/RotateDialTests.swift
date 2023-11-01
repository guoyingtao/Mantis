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
        // Test valid plus rotation with limitation
        var dialConfig = RotationDialConfig()
        dialConfig.rotationLimitType = .limit(degreeAngle: 45)
        setup(with: dialConfig)
        
        var dialPlateTransform = dialPlate.transform
        var angle = Angle(degrees: 40)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        
        // Test invalid plus rotation with limitation
        dialConfig.rotationLimitType = .limit(degreeAngle: 45)
        setup(with: dialConfig)
        
        dialPlateTransform = dialPlate.transform
        angle = Angle(degrees: 50)
        XCTAssertFalse(dial.updateRotationValue(by: angle))
        XCTAssertNotEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: Angle(degrees: 0).radians))
        
        // Test valid minus rotation with limitation
        dialConfig.rotationLimitType = .limit(degreeAngle: 45)
        setup(with: dialConfig)
        
        dialPlateTransform = dialPlate.transform
        angle = Angle(degrees: -40)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        
        // Test invalid minus rotation with limitation
        dialConfig.rotationLimitType = .limit(degreeAngle: 45)
        setup(with: dialConfig)
        
        dialPlateTransform = dialPlate.transform
        angle = Angle(degrees: -50)
        XCTAssertFalse(dial.updateRotationValue(by: angle))
        XCTAssertNotEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: Angle(degrees: 0).radians))
        
        // Test no limit
        dialConfig = RotationDialConfig()
        dialConfig.rotationLimitType = .noLimit
        setup(with: dialConfig)
        
        dialPlateTransform = dialPlate.transform
        angle = Angle(degrees: 70)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
    }
    
    func testReset() {
        var dialConfig = RotationDialConfig()
        dialConfig.rotationLimitType = .limit(degreeAngle: 45)
        setup(with: dialConfig)
        
        let dialPlateTransform = dialPlate.transform
        let angle = Angle(degrees: 40)
        XCTAssertTrue(dial.updateRotationValue(by: angle))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))

        dial.reset()
        XCTAssertEqual(viewModel.rotationAngle.degrees, 0)
        XCTAssertEqual(dial.transform, .identity)
    }

}
