//
//  BandcampParser.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Builds typed models from Bandcamp's extracted `data-tralbum` / `data-band`
/// JSON plus supplementary page bits (tags, currency, bio, location).
enum BandcampParser {

    // MARK: - Release

    static func release(
        tralbum: [String: Any],
        band: [String: Any]?,
        html: String,
        host: String
    ) -> BandcampRelease {
        let current = tralbum["current"] as? [String: Any] ?? [:]
        let artist = (tralbum["artist"] as? String) ?? (current["artist"] as? String) ?? ""
        let minimumPrice = doubleValue(current["minimum_price"])

        let tracks = (tralbum["trackinfo"] as? [[String: Any]] ?? []).map { track($0, host: host) }
        let packages = (tralbum["packages"] as? [[String: Any]] ?? []).map(package)

        return BandcampRelease(
            id: intValue(tralbum["id"]) ?? 0,
            itemType: tralbum["item_type"] as? String ?? "album",
            url: tralbum["url"] as? String ?? "",
            title: current["title"] as? String ?? "",
            artist: artist,
            artistID: intValue(current["band_id"]) ?? intValue(band?["id"]),
            releaseDate: date(current["release_date"] ?? tralbum["album_release_date"]),
            about: nonEmpty(current["about"]),
            credits: nonEmpty(current["credits"]),
            minimumPrice: minimumPrice,
            currency: BandcampExtractor.currency(in: html),
            isNameYourPrice: (minimumPrice ?? 0) == 0 && (current["is_set_price"] as? Bool) != true,
            artworkID: intValue(tralbum["art_id"]),
            tags: BandcampExtractor.tags(in: html),
            tracks: tracks,
            packages: packages,
            hasVideo: boolValue(tralbum["has_video"]),
            isPreorder: boolValue(tralbum["is_preorder"]),
            upc: nonEmpty(current["upc"])
        )
    }

    private static func track(_ d: [String: Any], host: String) -> BandcampTrack {
        let streamURL = (d["file"] as? [String: Any])?["mp3-128"] as? String
        let titleLink = d["title_link"] as? String
        return BandcampTrack(
            id: intValue(d["track_id"]) ?? intValue(d["id"]) ?? 0,
            trackNumber: intValue(d["track_num"]),
            title: d["title"] as? String ?? "",
            artist: nonEmpty(d["artist"]),
            duration: doubleValue(d["duration"]),
            streamURL: streamURL,
            isStreamable: streamURL != nil || boolValue(d["streaming"]),
            isDownloadable: boolValue(d["is_downloadable"]),
            hasLyrics: boolValue(d["has_lyrics"]),
            lyrics: nonEmpty(d["lyrics"]),
            playCount: intValue(d["play_count"]),
            url: absolute(titleLink, host: host)
        )
    }

    private static func package(_ d: [String: Any]) -> BandcampPackage {
        BandcampPackage(
            id: intValue(d["id"]),
            title: nonEmpty(d["title"]),
            typeName: nonEmpty(d["type_name"]),
            price: doubleValue(d["price"]),
            currency: nonEmpty(d["currency"]),
            description: nonEmpty(d["description"]),
            editionSize: intValue(d["edition_size"])
        )
    }

    // MARK: - Artist

    static func artist(
        band: [String: Any],
        discography: [[String: Any]],
        html: String,
        host: String
    ) -> BandcampArtist {
        BandcampArtist(
            id: intValue(band["id"]) ?? 0,
            name: band["name"] as? String ?? "",
            subdomain: nonEmpty(band["subdomain"]),
            url: (band["url"] as? String) ?? (band["https_url"] as? String) ?? "https://\(host)",
            location: BandcampExtractor.location(in: html),
            bio: BandcampExtractor.metaDescription(in: html),
            isLabel: boolValue(band["is_label"]),
            imageID: intValue(band["image_id"]),
            discography: discography.map { summary($0, host: host) }
        )
    }

    private static func summary(_ d: [String: Any], host: String) -> BandcampReleaseSummary {
        let pageURL = d["page_url"] as? String ?? ""
        return BandcampReleaseSummary(
            id: intValue(d["id"]) ?? 0,
            title: d["title"] as? String ?? "",
            artist: nonEmpty(d["artist"]),
            url: absolute(pageURL, host: host) ?? "https://\(host)",
            artworkID: intValue(d["art_id"]),
            type: d["type"] as? String ?? "album"
        )
    }

    /// A link from a page, made absolute without being made wrong.
    ///
    /// Most of these are paths and want the host in front. Some already carry
    /// their own: a label's discography lists records that live on the
    /// artist's own subdomain, and those arrive absolute. Prefixing those
    /// produced `https://label.bandcamp.comhttps://artist.bandcamp.com/album/x`
    /// — a URL that is obviously broken to a reader and silently broken to
    /// anything that follows it.
    static func absolute(_ link: String?, host: String) -> String? {
        guard let link, !link.isEmpty else { return nil }
        if link.hasPrefix("http://") || link.hasPrefix("https://") { return link }
        if link.hasPrefix("//") { return "https:\(link)" }
        if link.hasPrefix("/") { return "https://\(host)\(link)" }
        return "https://\(host)/\(link)"
    }

    // MARK: - Search

    static func searchResults(_ results: [[String: Any]]) -> [BandcampSearchResult] {
        results.map { d in
            BandcampSearchResult(
                id: intValue(d["id"]) ?? 0,
                type: BandcampResultType(code: d["type"] as? String),
                name: d["name"] as? String ?? "",
                artist: nonEmpty(d["band_name"]),
                url: nonEmpty(d["item_url_path"]) ?? nonEmpty(d["item_url_root"]),
                artworkID: intValue(d["art_id"]),
                imageID: intValue(d["img_id"]),
                location: nonEmpty(d["location"]),
                genre: nonEmpty(d["genre_name"]),
                tags: (d["tag_names"] as? [String]) ?? [],
                isLabel: boolValue(d["is_label"])
            )
        }
    }

    // MARK: - Helpers

    private static func nonEmpty(_ value: Any?) -> String? {
        guard let s = value as? String, !s.isEmpty else { return nil }
        return s
    }

    private static func boolValue(_ value: Any?) -> Bool {
        if let b = value as? Bool { return b }
        if let i = value as? Int { return i != 0 }
        return false
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let s = value as? String { return Int(s) }
        return nil
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        if let s = value as? String { return Double(s) }
        return nil
    }

    /// Parses Bandcamp's `"04 Mar 2011 00:00:00 GMT"` date format.
    private static func date(_ value: Any?) -> Date? {
        guard let s = value as? String, !s.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: s)
    }
}
