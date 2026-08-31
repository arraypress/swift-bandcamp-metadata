//
//  SupportTests.swift
//  BandcampMetadataTests
//
//  Created by David Sherlock on 2026.
//
//  The extracted rules pinned directly — no model constructed.
//

import XCTest
@testable import BandcampMetadata

final class SupportTests: XCTestCase {

    func testImageURLAssembly() {
        XCTAssertEqual(ImageURL.artwork(artID: 123, size: .large), "https://f4.bcbits.com/img/a123_10.jpg")
        XCTAssertEqual(ImageURL.artwork(artID: 123, size: .thumbnail), "https://f4.bcbits.com/img/a123_7.jpg")
        XCTAssertEqual(ImageURL.image(imageID: 456, size: .medium), "https://f4.bcbits.com/img/456_16.jpg",
                       "artist images take no 'a' prefix")
    }

    func testTrackDurationNeverFoldsIntoHours() {
        XCTAssertEqual(Formatting.trackDuration(seconds: 59), "0:59")
        XCTAssertEqual(Formatting.trackDuration(seconds: 65 * 60), "65:00")
    }
}
