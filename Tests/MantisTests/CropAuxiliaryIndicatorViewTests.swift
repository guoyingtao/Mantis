//
//  CropAuxiliaryIndicatorViewTests.swift
//  MantisTests
//
//  Created by Yingtao Guo on 2/26/23.
//

import XCTest
@testable import Mantis

final class CropAuxiliaryIndicatorViewTests: XCTestCase {
    
    var cropAuxiliaryIndicatorView: CropAuxiliaryIndicatorView!

    override func setUpWithError() throws {
        cropAuxiliaryIndicatorView = CropAuxiliaryIndicatorView(frame: .zero, cropBoxHotAreaUnit: 42)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitWithCoder() throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: cropAuxiliaryIndicatorView!, requiringSecureCoding: false)
        let coder = try XCTUnwrap(NSKeyedUnarchiver(forReadingFrom: data))
        let cropAuxiliaryIndicatorView = CropAuxiliaryIndicatorView(coder: coder)
        XCTAssertNotNil(cropAuxiliaryIndicatorView)
    }
    
    func testDidMoveToSuperview() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        container.addSubview(cropAuxiliaryIndicatorView)
        
        for subview in cropAuxiliaryIndicatorView.subviews {
            XCTAssertEqual(subview.frame, .zero)
        }
        
        cropAuxiliaryIndicatorView = CropAuxiliaryIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), cropBoxHotAreaUnit: 42)
        
        for subview in cropAuxiliaryIndicatorView.subviews {
            XCTAssertEqual(subview.frame, .zero)
        }
        
        container.addSubview(cropAuxiliaryIndicatorView)
        
        for subview in cropAuxiliaryIndicatorView.subviews {
            XCTAssertNotEqual(subview.frame, .zero)
        }
    }
    
    func testFrameChange() {
        let subviewCount = cropAuxiliaryIndicatorView.subviews.count
        
        cropAuxiliaryIndicatorView.handleIndicatorHandleTouched(with: .top)
        XCTAssertEqual(cropAuxiliaryIndicatorView.subviews.count, subviewCount + 1)
        XCTAssertEqual(cropAuxiliaryIndicatorView.gridLineNumberType, .crop)

        cropAuxiliaryIndicatorView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        XCTAssertEqual(cropAuxiliaryIndicatorView.subviews.count, subviewCount + 1)
        XCTAssertEqual(cropAuxiliaryIndicatorView.gridLineNumberType, .crop)        
    }
        
    func testHandleCornerHandleTouched() {
        let subviewCount = cropAuxiliaryIndicatorView.subviews.count
        cropAuxiliaryIndicatorView.handleIndicatorHandleTouched(with: .none)
        XCTAssertEqual(cropAuxiliaryIndicatorView.subviews.count, subviewCount)
        
        cropAuxiliaryIndicatorView.handleIndicatorHandleTouched(with: .top)
        XCTAssertEqual(cropAuxiliaryIndicatorView.subviews.count, subviewCount + 1)
        XCTAssertEqual(cropAuxiliaryIndicatorView.gridLineNumberType, .crop)
        
        cropAuxiliaryIndicatorView.handleEdgeUntouched()
        
        cropAuxiliaryIndicatorView.handleIndicatorHandleTouched(with: .bottom)
        XCTAssertEqual(cropAuxiliaryIndicatorView.subviews.count, subviewCount + 1)
        XCTAssertEqual(cropAuxiliaryIndicatorView.gridLineNumberType, .crop)
        
        cropAuxiliaryIndicatorView.handleEdgeUntouched()
        
        cropAuxiliaryIndicatorView.handleIndicatorHandleTouched(with: .left)
        XCTAssertEqual(cropAuxiliaryIndicatorView.subviews.count, subviewCount + 1)
        XCTAssertEqual(cropAuxiliaryIndicatorView.gridLineNumberType, .crop)
        
        cropAuxiliaryIndicatorView.handleEdgeUntouched()
        
        cropAuxiliaryIndicatorView.handleIndicatorHandleTouched(with: .right)
        XCTAssertEqual(cropAuxiliaryIndicatorView.subviews.count, subviewCount + 1)
        XCTAssertEqual(cropAuxiliaryIndicatorView.gridLineNumberType, .crop)
        
        cropAuxiliaryIndicatorView.handleEdgeUntouched()
        
        cropAuxiliaryIndicatorView.handleIndicatorHandleTouched(with: .topLeft)
        XCTAssertEqual(cropAuxiliaryIndicatorView.subviews.count, subviewCount)
        XCTAssertEqual(cropAuxiliaryIndicatorView.gridLineNumberType, .crop)
    }
    
    func testHandleEdgeUntouched() {
        let subviewCount = cropAuxiliaryIndicatorView.subviews.count
        cropAuxiliaryIndicatorView.handleIndicatorHandleTouched(with: .top)
        XCTAssertEqual(cropAuxiliaryIndicatorView.subviews.count, subviewCount + 1)

        cropAuxiliaryIndicatorView.handleEdgeUntouched()
        XCTAssertTrue(cropAuxiliaryIndicatorView.gridHidden)
        XCTAssertEqual(cropAuxiliaryIndicatorView.subviews.count, subviewCount)
    }
}
