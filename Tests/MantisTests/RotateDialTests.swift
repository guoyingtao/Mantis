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
        let dialConfig = Config().cropViewConfig.dialConfig
        setup(with: dialConfig)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    private func setup(with dialConfig: DialConfig) {
        viewModel = RotationDialViewModel()
        dialPlate = RotationDialPlate(frame: .zero, dialConfig: dialConfig)
        dial = RotationDial(frame: .zero,
                            dialConfig: dialConfig,
                            viewModel: viewModel,
                            dialPlate: dialPlate)
        dial.setup(with: .zero)
    }
    
    func testRotateDialPlate() {
        // Test valid plus rotation with limitation
        var dialConfig = Config().cropViewConfig.dialConfig
        dialConfig.rotationLimitType = .limit(angle: CGAngle(degrees: 45))
        setup(with: dialConfig)
        
        var dialPlateTransform = dialPlate.transform
        var angle = CGAngle(degrees: 40)
        XCTAssertTrue(dial.rotateDialPlate(by: angle))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        
        // Test invalid plus rotation with limitation
        dialConfig.rotationLimitType = .limit(angle: CGAngle(degrees: 45))
        setup(with: dialConfig)
        
        dialPlateTransform = dialPlate.transform
        angle = CGAngle(degrees: 50)
        XCTAssertFalse(dial.rotateDialPlate(by: angle))
        XCTAssertNotEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: CGAngle(degrees: 45).radians))
        
        // Test valid minus rotation with limitation
        dialConfig.rotationLimitType = .limit(angle: CGAngle(degrees: 45))
        setup(with: dialConfig)
        
        dialPlateTransform = dialPlate.transform
        angle = CGAngle(degrees: -40)
        XCTAssertTrue(dial.rotateDialPlate(by: angle))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        
        // Test invalid minus rotation with limitation
        dialConfig.rotationLimitType = .limit(angle: CGAngle(degrees: 45))
        setup(with: dialConfig)
        
        dialPlateTransform = dialPlate.transform
        angle = CGAngle(degrees: -50)
        XCTAssertFalse(dial.rotateDialPlate(by: angle))
        XCTAssertNotEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: CGAngle(degrees: -45).radians))
        
        // Test no limit
        dialConfig = Config().cropViewConfig.dialConfig
        dialConfig.rotationLimitType = .noLimit
        setup(with: dialConfig)
        
        dialPlateTransform = dialPlate.transform
        angle = CGAngle(degrees: 70)
        XCTAssertTrue(dial.rotateDialPlate(by: angle))
        XCTAssertEqual(dialPlate.transform, dialPlateTransform.rotated(by: angle.radians))
    }
}
