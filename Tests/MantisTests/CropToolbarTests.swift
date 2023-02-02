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
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
