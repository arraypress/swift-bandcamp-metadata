//
//  BandcampSearchType.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Restricts a Bandcamp search to a single result type.
///
/// The raw value is the `search_filter` the search endpoint expects.
public enum BandcampSearchType: String, Sendable {
    /// All result types.
    case all = ""
    /// Artists and labels.
    case artists = "b"
    /// Albums.
    case albums = "a"
    /// Tracks.
    case tracks = "t"
    /// Labels.
    case labels = "l"
}

/// The type of a Bandcamp search result.
public enum BandcampResultType: String, Sendable {
    /// An artist / band.
    case artist = "b"
    /// An album.
    case album = "a"
    /// A track.
    case track = "t"
    /// A label.
    case label = "l"
    /// A fan.
    case fan = "f"
    /// An unrecognised type.
    case unknown = ""

    init(code: String?) {
        self = code.flatMap(BandcampResultType.init(rawValue:)) ?? .unknown
    }
}
