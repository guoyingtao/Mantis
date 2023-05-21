//
//  CropWorkbenchViewTests.swift
//  MantisTests
//
//  Created by Yingtao Guo on 2/14/23.
//

import XCTest
@testable import Mantis

final class CropWorkbenchViewTests: XCTestCase {
    
    var workbenchView = CropWorkbenchView(frame: .zero, minimumZoomScale: 1.0, maximumZoomScale: 15, imageContainer: FakeImageContainer(frame: .zero))

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUpdateMinZoomScale() {
        let fakeImageContainer = FakeImageContainer(frame: .init(x: 0, y: 0, width: 200, height: 100))
        workbenchView = CropWorkbenchView(frame: .zero,
                                         minimumZoomScale: 1.0,
                                         maximumZoomScale: 15,
                                         imageContainer: fakeImageContainer)
        workbenchView.bounds = CGRect(x: 0, y: 0, width: 400, height: 100)
        workbenchView.updateMinZoomScale()
        
        XCTAssertEqual(workbenchView.minimumZoomScale, 2)
        
        workbenchView = CropWorkbenchView(frame: .zero,
                                         minimumZoomScale: 1.0,
                                         maximumZoomScale: 15,
                                         imageContainer: fakeImageContainer)
        workbenchView.bounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        workbenchView.updateMinZoomScale()
        
        XCTAssertEqual(workbenchView.minimumZoomScale, 3)
    }

    func testShouldScale() {
        workbenchView.bounds = CGRect(x: 0, y: 0, width: 200, height: 100)
        workbenchView.contentSize = CGSize(width: 200, height: 100)
        XCTAssertTrue(workbenchView.shouldScale())
        
        workbenchView.bounds = CGRect(x: 0, y: 0, width: 200, height: 100)
        workbenchView.contentSize = CGSize(width: 100, height: 80)
        XCTAssertTrue(workbenchView.shouldScale())
        
        workbenchView.bounds = CGRect(x: 0, y: 0, width: 200, height: 100)
        workbenchView.contentSize = CGSize(width: 300, height: 200)
        XCTAssertFalse(workbenchView.shouldScale())
    }
}
