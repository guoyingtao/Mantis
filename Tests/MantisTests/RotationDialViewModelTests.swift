//
//  RotationDialViewModelTests.swift
//  MantisTests
//
//  Created by yingtguo on 1/19/23.
//

import XCTest
@testable import Mantis

final class RotationDialViewModelTests: XCTestCase {
    var rotationDialViewModel = RotationDialViewModel()
    var outputRotationAngle = CGAngle(degrees: 0)
    
    override func setUpWithError() throws {
        rotationDialViewModel.setup(with: .zero)
        rotationDialViewModel.didSetRotationAngle = { angle in
            self.outputRotationAngle = angle
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testRotationZero() {
        rotationDialViewModel.touchPoint = CGPoint(x: 10, y: 0)
        rotationDialViewModel.touchPoint = CGPoint(x: 20, y: 0)
        
        XCTAssertEqual(outputRotationAngle.degrees, 0)
    }

    func testRotation90Degree() {
        rotationDialViewModel.touchPoint = CGPoint(x: 10, y: 0)
        rotationDialViewModel.touchPoint = CGPoint(x: 0, y: 10)
        
        XCTAssertEqual(outputRotationAngle.degrees, 90, accuracy: 0.001)
    }
    
    func testRotationMinus90Degree() {
        rotationDialViewModel.touchPoint = CGPoint(x: 10, y: 0)
        rotationDialViewModel.touchPoint = CGPoint(x: 0, y: -10)
        
        XCTAssertEqual(outputRotationAngle.degrees, -90, accuracy: 0.001)
    }
    
    func testRotationBetween0and90Degree() {
        rotationDialViewModel.touchPoint = CGPoint(x: 10, y: 0)
        rotationDialViewModel.touchPoint = CGPoint(x: 10, y: 50)
        
        XCTAssertGreaterThan(outputRotationAngle.degrees, 0)
        XCTAssertLessThan(outputRotationAngle.degrees, 90)
    }
    
    func testRotationBetweenMinus0andMinus90Degree() {
        rotationDialViewModel.touchPoint = CGPoint(x: 10, y: 0)
        rotationDialViewModel.touchPoint = CGPoint(x: 10, y: -50)
        
        XCTAssertGreaterThan(outputRotationAngle.degrees, -90)
        XCTAssertLessThan(outputRotationAngle.degrees, 0)
    }
    
    func testRotationBetween90and180Degree() {
        rotationDialViewModel.touchPoint = CGPoint(x: 10, y: 0)
        rotationDialViewModel.touchPoint = CGPoint(x: -10, y: 10)
        
        XCTAssertGreaterThan(outputRotationAngle.degrees, 90)
        XCTAssertLessThan(outputRotationAngle.degrees, 180)
    }
    
    func testRotationBetweenMinus90andMinus180Degree() {
        rotationDialViewModel.touchPoint = CGPoint(x: 10, y: 0)
        rotationDialViewModel.touchPoint = CGPoint(x: -10, y: -10)
        
        XCTAssertGreaterThan(outputRotationAngle.degrees, -180)
        XCTAssertLessThan(outputRotationAngle.degrees, -90)
    }

    func testRotationMinus180Degree() {
        rotationDialViewModel.touchPoint = CGPoint(x: 10, y: 0)
        rotationDialViewModel.touchPoint = CGPoint(x: -10, y: 0)
        
        XCTAssertEqual(outputRotationAngle.degrees, -180, accuracy: 0.001)
    }
}
