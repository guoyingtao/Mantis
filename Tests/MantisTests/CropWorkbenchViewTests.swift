//
//  CropWorkbenchViewTests.swift
//  MantisTests
//
//  Created by Yingtao Guo on 2/14/23.
//

import XCTest
@testable import Mantis

final class CropWorkbenchViewTests: XCTestCase {
    
    var workbechView = CropWorkbenchView(frame: .zero, minimumZoomScale: 1.0, maximumZoomScale: 15, imageContainer: FakeImageContainer(frame: .zero))

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUpdateMinZoomScale() {
        workbechView = CropWorkbenchView(frame: .zero, minimumZoomScale: 1.0, maximumZoomScale: 15, imageContainer: FakeImageContainer(frame: .init(x: 0, y: 0, width: 200, height: 100)))
        workbechView.bounds = CGRect(x: 0, y: 0, width: 400, height: 100)
        workbechView.updateMinZoomScale()
        
        XCTAssertEqual(workbechView.minimumZoomScale, 2)
        
        workbechView = CropWorkbenchView(frame: .zero, minimumZoomScale: 1.0, maximumZoomScale: 15, imageContainer: FakeImageContainer(frame: .init(x: 0, y: 0, width: 200, height: 100)))
        workbechView.bounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        workbechView.updateMinZoomScale()
        
        XCTAssertEqual(workbechView.minimumZoomScale, 3)
    }

    
    func testShouldScale() {
        workbechView.bounds = CGRect(x: 0, y: 0, width: 200, height: 100)
        workbechView.contentSize = CGSize(width: 200, height: 100)
        XCTAssertTrue(workbechView.shouldScale())
        
        workbechView.bounds = CGRect(x: 0, y: 0, width: 200, height: 100)
        workbechView.contentSize = CGSize(width: 100, height: 80)
        XCTAssertTrue(workbechView.shouldScale())
        
        workbechView.bounds = CGRect(x: 0, y: 0, width: 200, height: 100)
        workbechView.contentSize = CGSize(width: 300, height: 200)
        XCTAssertFalse(workbechView.shouldScale())
    }
}
