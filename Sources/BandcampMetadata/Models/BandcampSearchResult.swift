//
//  BandcampSearchResult.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single Bandcamp search result — an artist, album, track, or label.
///
/// The ``url`` of any result can be passed straight to
/// ``BandcampMetadata/release(_:)`` (albums/tracks) or
/// ``BandcampMetadata/artist(_:)`` (artists/labels) to fetch full detail.
public struct BandcampSearchResult: Sendable, Identifiable {

    /// The Bandcamp ID.
    public let id: Int

    /// The result type.
    public let type: BandcampResultType

    /// The item name (album/track title, or artist/label name).
    public let name: String

    /// The credited artist, for albums and tracks.
    public let artist: String?

    /// The item URL (the album/track page, or the artist/label page).
    public let url: String?

    /// The album/track artwork ID (`art_id`).
    public let artworkID: Int?

    /// The artist/label image ID (`img_id`).
    public let imageID: Int?

    /// The location, for artists/labels.
    public let location: String?

    /// The genre, for artists/labels.
    public let genre: String?

    /// The tags, for artists/labels.
    public let tags: [String]

    /// Whether the result is a label.
    public let isLabel: Bool

    // MARK: - Computed

    /// Whether this result is an album or track (has a `release` page).
    public var isRelease: Bool { type == .album || type == .track }

    /// An image URL at the given size — album/track artwork or artist image as appropriate.
    public func imageURL(size: BandcampImageSize = .medium) -> String? {
        if let artworkID { return size.artworkURL(artID: artworkID) }
        if let imageID { return size.imageURL(imageID: imageID) }
        return nil
    }

    public init(
        id: Int, type: BandcampResultType, name: String, artist: String?, url: String?,
        artworkID: Int?, imageID: Int?, location: String?, genre: String?, tags: [String], isLabel: Bool
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.artist = artist
        self.url = url
        self.artworkID = artworkID
        self.imageID = imageID
        self.location = location
        self.genre = genre
        self.tags = tags
        self.isLabel = isLabel
    }
}
