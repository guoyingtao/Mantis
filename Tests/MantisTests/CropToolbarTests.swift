//
//  CropToolbarTests.swift
//  MantisTests
//
//  Created by yingtguo on 2/2/23.
//

import XCTest
@testable import Mantis

final class CropToolbarTests: XCTestCase {
    
    var cropToolbar = CropToolbar(frame: .zero)

    override func setUpWithError() throws {
        var config = CropToolbarConfig()
        config.toolbarButtonOptions = .all
        cropToolbar.createToolbarUI(config: config)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSetup() {
        XCTAssertNotNil(doneButton)
        XCTAssertNotNil(cancelButton)
        XCTAssertNotNil(counterclockwiseRotationButton)
        XCTAssertNotNil(clockwiseRotationButton)
        XCTAssertNotNil(resetButton)
        XCTAssertNotNil(ratioButton)
        XCTAssertNotNil(alterCropper90DegreeButton)
        XCTAssertNotNil(horizontallyFlipButton)
        XCTAssertNotNil(verticallyFlipButton)
    }
    
    func testAccessibilities() {
        XCTAssertTrue(doneButton?.isAccessibilityElement == true)
        XCTAssertTrue(doneButton?.accessibilityTraits == .button)
        XCTAssertEqual(doneButton?.accessibilityLabel, "Done")
        
        XCTAssertTrue(cancelButton?.isAccessibilityElement == true)
        XCTAssertTrue(cancelButton?.accessibilityTraits == .button)
        XCTAssertEqual(cancelButton?.accessibilityLabel, "Cancel")
        
        XCTAssertTrue(clockwiseRotationButton?.isAccessibilityElement == true)
        XCTAssertTrue(clockwiseRotationButton?.accessibilityTraits == .button)
        XCTAssertEqual(clockwiseRotationButton?.accessibilityLabel, "Clockwise rotation")

        XCTAssertTrue(counterclockwiseRotationButton?.isAccessibilityElement == true)
        XCTAssertTrue(counterclockwiseRotationButton?.accessibilityTraits == .button)
        XCTAssertEqual(counterclockwiseRotationButton?.accessibilityLabel, "CounterClockwise rotation")
        
        XCTAssertTrue(alterCropper90DegreeButton?.isAccessibilityElement == true)
        XCTAssertTrue(alterCropper90DegreeButton?.accessibilityTraits == .button)
        XCTAssertEqual(alterCropper90DegreeButton?.accessibilityLabel, "Alter cropper by 90 degrees")

        XCTAssertTrue(horizontallyFlipButton?.isAccessibilityElement == true)
        XCTAssertTrue(horizontallyFlipButton?.accessibilityTraits == .button)
        XCTAssertEqual(horizontallyFlipButton?.accessibilityLabel, "Horizontally flip")
        
        XCTAssertTrue(verticallyFlipButton?.isAccessibilityElement == true)
        XCTAssertTrue(verticallyFlipButton?.accessibilityTraits == .button)
        XCTAssertEqual(verticallyFlipButton?.accessibilityLabel, "Vertically flip")
    }
    
    func testGetRatioListPresentSourceViewReturnNotNil() {
        var config = CropToolbarConfig()
        config.toolbarButtonOptions = .all
        config.ratioCandidatesShowType = .presentRatioListFromButton
        cropToolbar.createToolbarUI(config: config)
        
        XCTAssertNotNil(cropToolbar.getRatioListPresentSourceView())
    }
    
    func testGetRatioListPresentSourceViewReturnNil() {
        var config1 = CropToolbarConfig()
        config1.toolbarButtonOptions = []
        config1.ratioCandidatesShowType = .presentRatioListFromButton
        
        let cropToolbar1 = CropToolbar(frame: .zero)
        cropToolbar1.createToolbarUI(config: config1)
        XCTAssertNil(cropToolbar1.getRatioListPresentSourceView())
        
        var config2 = CropToolbarConfig()
        config2.toolbarButtonOptions = .all
        config2.ratioCandidatesShowType = .alwaysShowRatioList
        
        let cropToolbar2 = CropToolbar(frame: .zero)
        cropToolbar2.createToolbarUI(config: config2)
        XCTAssertNil(cropToolbar2.getRatioListPresentSourceView())
    }
    
    func testGetRatioListPresentSourceView() {
        var config = CropToolbarConfig()
        config.toolbarButtonOptions = .all
        config.ratioCandidatesShowType = .presentRatioListFromButton
        cropToolbar.createToolbarUI(config: config)
        
        XCTAssertNotNil(cropToolbar.getRatioListPresentSourceView())
    }
}

extension CropToolbarTests {
    private var doneButton: UIButton? {
        cropToolbar.findSubview(withAccessibilityIdentifier: "DoneButton") as? UIButton
    }
    
    private var cancelButton: UIButton? {
        cropToolbar.findSubview(withAccessibilityIdentifier: "CancelButton") as? UIButton
    }
    
    private var counterclockwiseRotationButton: UIButton? {
        cropToolbar.findSubview(withAccessibilityIdentifier: "CounterClockwiseRotationButton") as? UIButton
    }

    private var clockwiseRotationButton: UIButton? {
        cropToolbar.findSubview(withAccessibilityIdentifier: "ClockwiseRotationButton") as? UIButton
    }

    private var resetButton: UIButton? {
        cropToolbar.findSubview(withAccessibilityIdentifier: "ResetButton") as? UIButton
    }

    private var ratioButton: UIButton? {
        cropToolbar.findSubview(withAccessibilityIdentifier: "RatioButton") as? UIButton
    }

    private var alterCropper90DegreeButton: UIButton? {
        cropToolbar.findSubview(withAccessibilityIdentifier: "AlterCropper90DegreeButton") as? UIButton
    }

    private var horizontallyFlipButton: UIButton? {
        cropToolbar.findSubview(withAccessibilityIdentifier: "HorizontallyFlipButton") as? UIButton
    }

    private var verticallyFlipButton: UIButton? {
        cropToolbar.findSubview(withAccessibilityIdentifier: "VerticallyFlipButton") as? UIButton
    }
}
