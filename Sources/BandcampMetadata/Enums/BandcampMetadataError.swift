//
//  BandcampMetadataError.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Errors that can occur when extracting Bandcamp metadata.
///
/// ```swift
/// do {
///     let release = try await BandcampMetadata.release("https://c418.bandcamp.com/album/minecraft-volume-alpha")
/// } catch BandcampMetadataError.notFound {
///     print("No such release")
/// } catch {
///     print(error.localizedDescription)
/// }
/// ```
public enum BandcampMetadataError: Error, LocalizedError, Equatable, Sendable {

    /// The provided string is not a usable Bandcamp URL.
    case invalidURL

    /// The page was not found (`404`).
    case notFound

    /// Bandcamp is rate-limiting or blocking requests.
    case requestBlocked

    /// The expected embedded data (`data-tralbum` / `data-band`) was not found
    /// in the page — Bandcamp may have changed its markup.
    case dataNotFound

    /// A network request failed.
    case networkError(String)

    /// Failed to parse the extracted data.
    case parsingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Bandcamp URL. Provide an album, track, or artist URL (e.g. https://artist.bandcamp.com/album/name)."
        case .notFound:
            return "The Bandcamp page was not found."
        case .requestBlocked:
            return "Bandcamp is blocking or rate-limiting requests. Try again later."
        case .dataNotFound:
            return "Could not find the embedded Bandcamp data in the page (markup may have changed)."
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
