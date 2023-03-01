//
//  ImageContainerTests.swift
//  MantisTests
//
//  Created by yingtguo on 2/4/23.
//

import XCTest
@testable import Mantis

final class ImageContainerTests: XCTestCase {

    var imageContainer: ImageContainer!
    
    override func setUpWithError() throws {
        imageContainer = ImageContainer(image: UIImage())
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSetup() {
        XCTAssertNotNil(sourceImage)
    }
        
    func testGetCropRegion() {
        let frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        imageContainer.frame = frame
        
        let parentView = UIView(frame: frame)
        parentView.addSubview(imageContainer)
        
        var region = imageContainer.getCropRegion(withCropBoxFrame: frame, cropView: parentView)
        var expectedRegion = CropRegion(topLeft: CGPoint(x: 0, y: 0),
                                        topRight: CGPoint(x: 1, y: 0),
                                        bottomLeft: CGPoint(x: 0, y: 1),
                                        bottomRight: CGPoint(x: 1, y: 1))
        XCTAssertEqual(region, expectedRegion)
        
        let cropFrame = CGRect(x: 50, y: 25, width: 100, height: 50)
        region = imageContainer.getCropRegion(withCropBoxFrame: cropFrame, cropView: parentView)
        expectedRegion = CropRegion(topLeft: CGPoint(x: 0.25, y: 0.25),
                                    topRight: CGPoint(x: 0.75, y: 0.25),
                                    bottomLeft: CGPoint(x: 0.25, y: 0.75),
                                    bottomRight: CGPoint(x: 0.75, y: 0.75))
        XCTAssertEqual(region, expectedRegion)
        
        imageContainer.transform = CGAffineTransform(rotationAngle: .pi / 2)
        region = imageContainer.getCropRegion(withCropBoxFrame: cropFrame, cropView: parentView)
        expectedRegion = CropRegion(topLeft: CGPoint(x: 0.375, y: 1),
                                    topRight: CGPoint(x: 0.375, y: 0),
                                    bottomLeft: CGPoint(x: 0.625, y: 1),
                                    bottomRight: CGPoint(x: 0.625, y: 0))
        XCTAssertEqual(region, expectedRegion)
    }
}

extension ImageContainerTests {
    private var sourceImage: UIImageView? { imageContainer.findSubview(withAccessibilityIdentifier: "SourceImage") as? UIImageView
    }
}
