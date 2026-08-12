//
//  BandcampClient.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Fetches Bandcamp page HTML.
///
/// Bandcamp has no public API; this library extracts the JSON that Bandcamp
/// embeds in each page (the same data that powers its embed player).
enum BandcampClient {

    static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"

    /// Fetches the HTML for a Bandcamp URL.
    static func fetchHTML(_ urlString: String) async throws -> String {
        // Any host with a host component. Not restricted to bandcamp.com,
        // because artists can point a custom domain at their Bandcamp page and
        // those are ordinary, working URLs. (The previous condition read as a
        // bandcamp.com check but ended in `|| url.host != nil`, which admits
        // everything — the check was decorative.)
        guard let url = URL(string: urlString), url.host != nil else {
            throw BandcampMetadataError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw BandcampMetadataError.networkError(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200..<300: break
            case 404: throw BandcampMetadataError.notFound
            case 403, 429: throw BandcampMetadataError.requestBlocked
            default: throw BandcampMetadataError.networkError("HTTP \(http.statusCode)")
            }
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw BandcampMetadataError.parsingError("Failed to decode page HTML")
        }
        try checkInterstitial(html)
        return html
    }

    /// Pages that answer 200 without being the page that was asked for.
    ///
    /// Two of these exist and neither sets a status code that says so, which
    /// makes them the failures worth naming. A bot challenge is a 3 KB Fastly
    /// interstitial: transient, and worth retrying later. An unclaimed
    /// subdomain serves Bandcamp's signup form: permanent, and not an artist.
    ///
    /// Without this both arrive as ``BandcampMetadataError/dataNotFound`` —
    /// "the page had no data" — which is true and tells a caller nothing about
    /// whether trying again could ever work.
    static func checkInterstitial(_ html: String) throws {
        // Matched on the full title element rather than the words, so an album
        // that happens to be called Signup is not mistaken for one of these.
        if html.contains("<title>Client Challenge</title>") {
            throw BandcampMetadataError.requestBlocked
        }
        if html.contains("<title>Signup | Bandcamp</title>") {
            throw BandcampMetadataError.notFound
        }
    }

    /// POSTs a JSON body to a Bandcamp API endpoint and returns the parsed object.
    static func postJSON(_ urlString: String, body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: urlString) else { throw BandcampMetadataError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw BandcampMetadataError.networkError(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if http.statusCode == 403 || http.statusCode == 429 { throw BandcampMetadataError.requestBlocked }
            throw BandcampMetadataError.networkError("HTTP \(http.statusCode)")
        }

        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw BandcampMetadataError.parsingError("Invalid JSON response")
        }
        return json
    }
}
