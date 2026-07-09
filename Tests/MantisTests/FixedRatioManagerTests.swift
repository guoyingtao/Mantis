//
//  FixedRatioManagerTests.swift
//  MantisTests
//
//  Covers the aspect-ratio list builder: which entries each RatioOptions flag
//  contributes, RatioItemType's positive-ratio validation, de-duplication by
//  name, and the tail-sort that orders the ratios while keeping the first two
//  fixed entries in place.
//

import XCTest
@testable import Mantis

final class FixedRatioManagerTests: XCTestCase {

    // MARK: - RatioItemType validation

    func testRatioItemRejectsNonPositiveHorizontalRatio() {
        XCTAssertNil(RatioItemType(nameH: "x", ratioH: 0, nameV: "x", ratioV: 1))
        XCTAssertNil(RatioItemType(nameH: "x", ratioH: -1, nameV: "x", ratioV: 1))
    }

    func testRatioItemRejectsNonPositiveVerticalRatio() {
        XCTAssertNil(RatioItemType(nameH: "x", ratioH: 1, nameV: "x", ratioV: 0))
    }

    func testRatioItemAcceptsPositiveRatios() {
        let item = RatioItemType(nameH: "3:2", ratioH: 1.5, nameV: "2:3", ratioV: 2.0 / 3.0)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.ratioH, 1.5)
        XCTAssertEqual(item?.nameH, "3:2")
    }

    // MARK: - RatioOptions contributions

    func testEmptyOptionsProduceNoRatios() {
        let manager = FixedRatioManager(type: .horizontal, originalRatioH: 1.0, ratioOptions: [])
        XCTAssertTrue(manager.ratios.isEmpty)
    }

    func testSquareOptionAddsSingleUnitRatio() {
        let manager = FixedRatioManager(type: .horizontal, originalRatioH: 1.0, ratioOptions: [.square])
        XCTAssertEqual(manager.ratios.count, 1)
        XCTAssertEqual(manager.ratios.first?.ratioH, 1.0)
        XCTAssertEqual(manager.ratios.first?.ratioV, 1.0)
    }

    func testOriginalOptionUsesOriginalRatioH() {
        let manager = FixedRatioManager(type: .horizontal, originalRatioH: 1.5, ratioOptions: [.original])
        XCTAssertEqual(manager.ratios.count, 1)
        XCTAssertEqual(manager.ratios.first?.ratioH, 1.5)
        XCTAssertEqual(manager.ratios.first?.ratioV, 1.5)
    }

    func testExtraDefaultRatiosAddSixEntries() {
        let manager = FixedRatioManager(type: .horizontal, originalRatioH: 1.0, ratioOptions: [.extraDefaultRatios])
        XCTAssertEqual(manager.ratios.count, 6)
        let names = manager.ratios.map { $0.nameH }
        XCTAssertEqual(Set(names), Set(["3:2", "5:3", "4:3", "5:4", "7:5", "16:9"]))
    }

    func testAllOptionsWithoutCustomProduceEightEntries() {
        // original(1) + square(1) + extraDefaultRatios(6) = 8
        let manager = FixedRatioManager(type: .horizontal, originalRatioH: 1.0, ratioOptions: .all)
        XCTAssertEqual(manager.ratios.count, 8)
    }

    // MARK: - Custom ratios & de-duplication

    func testCustomRatiosAreAppended() {
        let custom = [RatioItemType(nameH: "21:9", ratioH: 21.0 / 9.0, nameV: "9:21", ratioV: 9.0 / 21.0)!]
        let manager = FixedRatioManager(type: .horizontal, originalRatioH: 1.0,
                                        ratioOptions: [.custom], customRatios: custom)
        XCTAssertEqual(manager.ratios.count, 1)
        XCTAssertEqual(manager.ratios.first?.nameH, "21:9")
    }

    func testDuplicateNamedCustomRatioIsDropped() {
        // Two entries share nameH "9:9"; the second must be de-duplicated away.
        let custom = [
            RatioItemType(nameH: "9:9", ratioH: 1.0, nameV: "9:9", ratioV: 1.0)!,
            RatioItemType(nameH: "9:9", ratioH: 1.0, nameV: "9:9", ratioV: 1.0)!
        ]
        let manager = FixedRatioManager(type: .horizontal, originalRatioH: 1.0,
                                        ratioOptions: [.custom], customRatios: custom)
        XCTAssertEqual(manager.ratios.count, 1)
    }

    // MARK: - Tail sort keeps the first two entries in place

    func testHorizontalSortOrdersTailByHeightKeepingFirstTwoFixed() {
        // Five custom ratios; the tail after the first two is out of order by
        // height. Horizontal sort orders the tail ascending by the height in
        // "W:H", while the first two entries stay put.
        let custom = [
            RatioItemType(nameH: "10:1", ratioH: 10, nameV: "1:10", ratioV: 0.1)!, // fixed head
            RatioItemType(nameH: "10:2", ratioH: 5, nameV: "2:10", ratioV: 0.2)!,  // fixed head
            RatioItemType(nameH: "10:9", ratioH: 10.0 / 9, nameV: "9:10", ratioV: 0.9)!,
            RatioItemType(nameH: "10:3", ratioH: 10.0 / 3, nameV: "3:10", ratioV: 0.3)!,
            RatioItemType(nameH: "10:7", ratioH: 10.0 / 7, nameV: "7:10", ratioV: 0.7)!
        ]
        let manager = FixedRatioManager(type: .horizontal, originalRatioH: 1.0,
                                        ratioOptions: [.custom], customRatios: custom)
        XCTAssertEqual(manager.ratios.map { $0.nameH },
                       ["10:1", "10:2", "10:3", "10:7", "10:9"])
    }
}
