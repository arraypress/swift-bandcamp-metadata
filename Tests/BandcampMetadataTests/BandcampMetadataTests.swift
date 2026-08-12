//
//  BandcampMetadataTests.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import BandcampMetadata

final class BandcampMetadataTests: XCTestCase {

    // MARK: - Image URLs

    func testImageURLs() {
        XCTAssertEqual(
            BandcampImageSize.large.artworkURL(artID: 3390257927),
            "https://f4.bcbits.com/img/a3390257927_10.jpg"
        )
        XCTAssertEqual(
            BandcampImageSize.medium.imageURL(imageID: 12345),
            "https://f4.bcbits.com/img/12345_16.jpg"
        )
    }

    // MARK: - Extraction

    func testExtractEmbeddedJSON() {
        let tralbum = BandcampExtractor.jsonObject(attribute: "data-tralbum", in: Fixture.albumHTML)
        XCTAssertNotNil(tralbum)
        XCTAssertEqual(tralbum?["item_type"] as? String, "album")

        let tags = BandcampExtractor.tags(in: Fixture.albumHTML)
        XCTAssertEqual(tags, ["soundtrack", "ambient", "Leipzig"])

        XCTAssertEqual(BandcampExtractor.currency(in: Fixture.albumHTML), "USD")
    }

    // MARK: - Release parsing

    func testParseRelease() throws {
        let tralbum = try XCTUnwrap(BandcampExtractor.jsonObject(attribute: "data-tralbum", in: Fixture.albumHTML))
        let band = BandcampExtractor.jsonObject(attribute: "data-band", in: Fixture.albumHTML)
        let release = BandcampParser.release(tralbum: tralbum, band: band, html: Fixture.albumHTML, host: "c418.bandcamp.com")

        XCTAssertEqual(release.id, 1349219244)
        XCTAssertEqual(release.itemType, "album")
        XCTAssertEqual(release.title, "Minecraft - Volume Alpha")
        XCTAssertEqual(release.artist, "C418")
        XCTAssertEqual(release.minimumPrice, 6.0)
        XCTAssertEqual(release.currency, "USD")
        XCTAssertEqual(release.artworkID, 3390257927)
        XCTAssertEqual(release.artworkURL(size: .large), "https://f4.bcbits.com/img/a3390257927_10.jpg")
        XCTAssertEqual(release.tags, ["soundtrack", "ambient", "Leipzig"])
        XCTAssertNotNil(release.releaseDate)
        XCTAssertEqual(release.about, "It's me your favourite music man.")

        XCTAssertEqual(release.tracks.count, 2)
        let key = release.tracks[0]
        XCTAssertEqual(key.title, "Key")
        XCTAssertEqual(key.trackNumber, 1)
        XCTAssertEqual(key.duration, 65.0)
        XCTAssertEqual(key.formattedDuration, "1:05")
        XCTAssertEqual(key.streamURL, "https://t4.bcbits.com/stream/key.mp3")
        XCTAssertTrue(key.isStreamable)

        let ward = release.tracks[1]
        XCTAssertTrue(ward.hasLyrics)
        XCTAssertEqual(ward.lyrics, "la la la")

        XCTAssertEqual(release.packages.count, 1)
        XCTAssertEqual(release.packages[0].typeName, "Vinyl LP")
        XCTAssertEqual(release.packages[0].price, 30.0)
    }

    // MARK: - Search parsing

    func testSearchTypeFilters() {
        XCTAssertEqual(BandcampSearchType.albums.rawValue, "a")
        XCTAssertEqual(BandcampSearchType.tracks.rawValue, "t")
        XCTAssertEqual(BandcampSearchType.all.rawValue, "")
        XCTAssertEqual(BandcampResultType(code: "b"), .artist)
        XCTAssertEqual(BandcampResultType(code: "x"), .unknown)
    }

    func testParseSearchResults() throws {
        let raw = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(Fixture.searchJSON.utf8)) as? [String: Any])
        let results = BandcampParser.searchResults(((raw["auto"] as? [String: Any])?["results"] as? [[String: Any]]) ?? [])
        XCTAssertEqual(results.count, 2)

        let artist = results[0]
        XCTAssertEqual(artist.type, .artist)
        XCTAssertEqual(artist.name, "Aphex Twin")
        XCTAssertEqual(artist.url, "https://aphextwin.bandcamp.com")   // item_url_root
        XCTAssertEqual(artist.location, "UK")
        XCTAssertEqual(artist.imageURL(size: .medium), "https://f4.bcbits.com/img/36351072_16.jpg")

        let album = results[1]
        XCTAssertEqual(album.type, .album)
        XCTAssertEqual(album.name, "Drukqs")
        XCTAssertEqual(album.artist, "Aphex Twin")
        XCTAssertEqual(album.url, "https://aphextwin.bandcamp.com/album/drukqs")   // item_url_path
        XCTAssertTrue(album.isRelease)
    }

    // MARK: - Live tests (keyless — network only)

    func testLiveRelease() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["BANDCAMP_LIVE_TESTS"] == "1",
                          "Set BANDCAMP_LIVE_TESTS=1 to run.")
        let release = try await BandcampMetadata.release("https://c418.bandcamp.com/album/minecraft-volume-alpha")
        XCTAssertEqual(release.artist, "C418")
        XCTAssertFalse(release.tracks.isEmpty)
        XCTAssertTrue(release.tracks.contains { $0.streamURL != nil })

        let artist = try await BandcampMetadata.artist("https://c418.bandcamp.com")
        XCTAssertEqual(artist.name, "C418")
        XCTAssertFalse(artist.discography.isEmpty)

        let search = try await BandcampMetadata.search("aphex twin", type: .albums)
        XCTAssertFalse(search.isEmpty)
        XCTAssertTrue(search.allSatisfy { $0.type == .album })
        XCTAssertTrue(search.allSatisfy { $0.url != nil })

        if ProcessInfo.processInfo.environment["BANDCAMP_PRINT"] == "1" {
            print("=== \(release.artist) – \(release.title) ===")
            print("\(release.trackCount) tracks · \(release.minimumPrice ?? 0) \(release.currency ?? "") · tags: \(release.tags.joined(separator: ", "))")
            for t in release.tracks.prefix(4) {
                print("  \(t.trackNumber ?? 0). \(t.title) [\(t.formattedDuration)] \(t.streamURL != nil ? "▶" : "")")
            }
            print("artist: \(artist.name) (\(artist.location ?? "?")) — \(artist.discography.count) releases")
        }
    }
    // MARK: - Pages that answer 200 without being the page you asked for

    /// Bandcamp fronts a Fastly bot challenge that arrives as a 3 KB body with
    /// HTTP 200. Status-code handling never sees it, so before this it reached
    /// the parser and came back as `dataNotFound` — indistinguishable from a
    /// page that genuinely has no data, and the difference is whether trying
    /// again could ever work.
    func testABotChallengeIsReportedAsBlockedNotEmpty() {
        let challenge = """
            <!DOCTYPE html><html lang="en"><head>\
            <title>Client Challenge</title></head><body></body></html>
            """
        XCTAssertThrowsError(try BandcampClient.checkInterstitial(challenge)) { error in
            XCTAssertEqual(error as? BandcampMetadataError, .requestBlocked)
        }
    }

    /// An unclaimed subdomain serves Bandcamp's signup form, also at 200.
    /// That one is permanent: there is no artist there and never was.
    func testAnUnclaimedSubdomainIsReportedAsNotFound() {
        let signup = "<html><head><title>Signup | Bandcamp</title></head><body></body></html>"
        XCTAssertThrowsError(try BandcampClient.checkInterstitial(signup)) { error in
            XCTAssertEqual(error as? BandcampMetadataError, .notFound)
        }
    }

    /// Matched on the whole title element, so a release that happens to be
    /// called Signup is still a release.
    func testARealPageIsNotMistakenForAnInterstitial() {
        XCTAssertNoThrow(try BandcampClient.checkInterstitial(Fixture.albumHTML))
        XCTAssertNoThrow(
            try BandcampClient.checkInterstitial("<title>Signup | Some Band</title>")
        )
        XCTAssertNoThrow(
            try BandcampClient.checkInterstitial("<title>Client Challenge EP | Some Band</title>")
        )
    }
}

// MARK: - Fixture (structurally faithful to a real Bandcamp album page)

private enum Fixture {
    // `data-tralbum` / `data-band` values are HTML-attribute-encoded (quotes as &quot;).
    static let albumHTML = """
    <html><head>
    <meta name="description" content="It&#39;s me your favourite music man." />
    </head><body>
    <script type="application/ld+json">{"offers":{"priceCurrency":"USD","price":6.0}}</script>
    <div data-band="{&quot;name&quot;:&quot;C418&quot;,&quot;id&quot;:3385865266,&quot;image_id&quot;:123}"
         data-tralbum="{&quot;item_type&quot;:&quot;album&quot;,&quot;id&quot;:1349219244,&quot;art_id&quot;:3390257927,&quot;artist&quot;:&quot;C418&quot;,&quot;album_release_date&quot;:&quot;04 Mar 2011 00:00:00 GMT&quot;,&quot;has_video&quot;:false,&quot;is_preorder&quot;:false,&quot;url&quot;:&quot;https://c418.bandcamp.com/album/minecraft-volume-alpha&quot;,&quot;current&quot;:{&quot;title&quot;:&quot;Minecraft - Volume Alpha&quot;,&quot;artist&quot;:&quot;C418&quot;,&quot;about&quot;:&quot;It&#39;s me your favourite music man.&quot;,&quot;credits&quot;:null,&quot;release_date&quot;:&quot;04 Mar 2011 00:00:00 GMT&quot;,&quot;minimum_price&quot;:6.0,&quot;is_set_price&quot;:false,&quot;band_id&quot;:3385865266,&quot;upc&quot;:null},&quot;trackinfo&quot;:[{&quot;track_id&quot;:1660675500,&quot;track_num&quot;:1,&quot;title&quot;:&quot;Key&quot;,&quot;duration&quot;:65.0,&quot;streaming&quot;:1,&quot;is_downloadable&quot;:true,&quot;has_lyrics&quot;:false,&quot;file&quot;:{&quot;mp3-128&quot;:&quot;https://t4.bcbits.com/stream/key.mp3&quot;},&quot;title_link&quot;:&quot;/track/key&quot;},{&quot;track_id&quot;:2,&quot;track_num&quot;:2,&quot;title&quot;:&quot;Ward&quot;,&quot;duration&quot;:225.0,&quot;streaming&quot;:1,&quot;has_lyrics&quot;:true,&quot;lyrics&quot;:&quot;la la la&quot;,&quot;file&quot;:{&quot;mp3-128&quot;:&quot;https://t4.bcbits.com/stream/ward.mp3&quot;}}],&quot;packages&quot;:[{&quot;id&quot;:99,&quot;title&quot;:&quot;Vinyl&quot;,&quot;type_name&quot;:&quot;Vinyl LP&quot;,&quot;price&quot;:30.0,&quot;currency&quot;:&quot;USD&quot;,&quot;edition_size&quot;:1000}]}">
    </div>
    <a class="tag" href="/tag/soundtrack">soundtrack</a>
    <a class="tag" href="/tag/ambient">ambient</a>
    <a class="tag" href="/tag/leipzig">Leipzig</a>
    </body></html>
    """

    static let searchJSON = """
    { "auto": { "results": [
        { "type": "b", "id": 1533096991, "name": "Aphex Twin", "band_name": null,
          "item_url_path": null, "item_url_root": "https://aphextwin.bandcamp.com",
          "art_id": null, "img_id": 36351072, "location": "UK", "genre_name": "Electronic",
          "tag_names": ["Electronic"], "is_label": false },
        { "type": "a", "id": 1308944319, "name": "Drukqs", "band_name": "Aphex Twin",
          "item_url_path": "https://aphextwin.bandcamp.com/album/drukqs",
          "item_url_root": "https://aphextwin.bandcamp.com", "art_id": 1701615096 }
    ] } }
    """

}
