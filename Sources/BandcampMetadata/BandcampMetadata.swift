//
//  BandcampMetadata.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Extract rich metadata from Bandcamp releases and artists.
///
/// Bandcamp has no public API, so this library reads the JSON that Bandcamp
/// embeds in every page (`data-tralbum` / `data-band` — the same data that
/// powers its embed player). No API key or authentication is required.
///
/// From a release it extracts the title, artist, release date, description,
/// credits, price, artwork, genre tags, physical packages, and the full
/// tracklist **including streaming/preview URLs and lyrics**. From an artist it
/// extracts the profile plus the complete discography.
///
/// ## Quick Start
///
/// ```swift
/// import BandcampMetadata
///
/// let release = try await BandcampMetadata.release(
///     "https://c418.bandcamp.com/album/minecraft-volume-alpha"
/// )
/// print("\(release.artist) – \(release.title) (\(release.trackCount) tracks)")
/// print(release.artworkURL() ?? "")
/// for t in release.tracks {
///     print("\(t.trackNumber ?? 0). \(t.title) [\(t.formattedDuration)] — \(t.streamURL ?? "no stream")")
/// }
///
/// let artist = try await BandcampMetadata.artist("https://c418.bandcamp.com")
/// print("\(artist.name) — \(artist.discography.count) releases")
/// ```
///
/// - Note: This relies on Bandcamp's page markup (no official API) and is
///   against Bandcamp's Terms of Service. The `data-tralbum` payload has been
///   stable for years, but use responsibly.
public enum BandcampMetadata {

    // MARK: - Public API

    /// Extracts a release (album or track) from its Bandcamp URL.
    ///
    /// Works for both album pages (`/album/…`) and single-track pages (`/track/…`);
    /// a track page yields a single-track release (``BandcampRelease/isSingleTrack``).
    ///
    /// - Parameter url: A Bandcamp album or track URL.
    /// - Throws: ``BandcampMetadataError`` if the page can't be fetched or parsed.
    /// - Returns: A fully-populated ``BandcampRelease``.
    public static func release(_ url: String) async throws -> BandcampRelease {
        let html = try await BandcampClient.fetchHTML(url)
        guard let tralbum = BandcampExtractor.jsonObject(attribute: "data-tralbum", in: html) else {
            throw BandcampMetadataError.dataNotFound
        }
        let band = BandcampExtractor.jsonObject(attribute: "data-band", in: html)
        let host = URL(string: url)?.host ?? ""
        return BandcampParser.release(tralbum: tralbum, band: band, html: html, host: host)
    }

    /// Extracts an artist/label profile and full discography from a Bandcamp URL.
    ///
    /// Accepts the artist root (`https://artist.bandcamp.com`), the `/music`
    /// page, or any page on the artist's subdomain — it resolves to the
    /// discography page automatically.
    ///
    /// - Parameter url: A Bandcamp artist URL.
    /// - Throws: ``BandcampMetadataError`` if the page can't be fetched or parsed.
    /// - Returns: A ``BandcampArtist`` with its discography.
    public static func artist(_ url: String) async throws -> BandcampArtist {
        let musicURL = normalizeArtistURL(url)
        let html = try await BandcampClient.fetchHTML(musicURL)
        guard let band = BandcampExtractor.jsonObject(attribute: "data-band", in: html) else {
            throw BandcampMetadataError.dataNotFound
        }
        let discography = BandcampExtractor.jsonArray(attribute: "data-client-items", in: html) ?? []
        let host = URL(string: musicURL)?.host ?? ""
        return BandcampParser.artist(band: band, discography: discography, html: html, host: host)
    }

    /// Searches Bandcamp for artists, albums, tracks, and labels.
    ///
    /// Each result's ``BandcampSearchResult/url`` can be passed to
    /// ``release(_:)`` (albums/tracks) or ``artist(_:)`` (artists/labels) for
    /// full detail.
    ///
    /// ```swift
    /// let results = try await BandcampMetadata.search("aphex twin", type: .albums)
    /// for r in results {
    ///     print("[\(r.type)] \(r.name) — \(r.artist ?? "") \(r.url ?? "")")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - query: The search text.
    ///   - type: Restrict to a result type. Defaults to ``BandcampSearchType/all``.
    /// - Throws: ``BandcampMetadataError`` if the request fails.
    /// - Returns: The matching results (Bandcamp returns up to ~50).
    public static func search(
        _ query: String,
        type: BandcampSearchType = .all
    ) async throws -> [BandcampSearchResult] {
        let body: [String: Any] = [
            "search_text": query,
            "search_filter": type.rawValue,
            "full_page": false,
            "fan_id": NSNull()
        ]
        let json = try await BandcampClient.postJSON(
            "https://bandcamp.com/api/bcsearch_public_api/1/autocomplete_elastic",
            body: body
        )
        let results = (json["auto"] as? [String: Any])?["results"] as? [[String: Any]] ?? []
        return BandcampParser.searchResults(results)
    }

    // MARK: - Helpers

    /// Reduces any URL on an artist's subdomain to their `/music` discography page.
    private static func normalizeArtistURL(_ url: String) -> String {
        guard let parsed = URL(string: url), let host = parsed.host else { return url }
        let scheme = parsed.scheme ?? "https"
        return "\(scheme)://\(host)/music"
    }
}
