//
//  BandcampRelease+Derived.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//
//  The release's and track's derived facts. Formatting and URL assembly
//  delegate into Support; the one-line derivations are stated in full.
//

import Foundation

extension BandcampTrack {

    /// The duration formatted as `"M:SS"`.
    public var formattedDuration: String {
        guard let duration else { return "0:00" }
        return Formatting.trackDuration(seconds: Int(duration.rounded()))
    }
}

extension BandcampRelease {

    /// The number of tracks.
    public var trackCount: Int { tracks.count }

    /// Whether this is a single-track release.
    public var isSingleTrack: Bool { itemType == "track" }

    /// The total running time of all tracks, in seconds.
    public var totalDuration: TimeInterval { tracks.reduce(0) { $0 + ($1.duration ?? 0) } }

    /// An artwork URL at the given size (defaults to ``BandcampImageSize/large``).
    public func artworkURL(size: BandcampImageSize = .large) -> String? {
        artworkID.map { ImageURL.artwork(artID: $0, size: size) }
    }
}
