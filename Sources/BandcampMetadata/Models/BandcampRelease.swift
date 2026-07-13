//
//  BandcampRelease.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single track within a Bandcamp release, including its streaming URL.
public struct BandcampTrack: Sendable, Identifiable {

    /// The Bandcamp track ID.
    public let id: Int

    /// The track number within the release (1-based).
    public let trackNumber: Int?

    /// The track title.
    public let title: String

    /// The track artist (for compilations / features), if different from the release artist.
    public let artist: String?

    /// The duration in seconds.
    public let duration: TimeInterval?

    /// The streaming/preview URL (128 kbps MP3), if the track is streamable.
    ///
    /// For name-your-price releases this is typically the full track; for paid
    /// releases it is a capped preview.
    public let streamURL: String?

    /// Whether the track can be streamed.
    public let isStreamable: Bool

    /// Whether the track is individually downloadable.
    public let isDownloadable: Bool

    /// Whether the track has lyrics.
    public let hasLyrics: Bool

    /// The lyrics, if present.
    public let lyrics: String?

    /// The number of plays, if exposed.
    public let playCount: Int?

    /// The absolute URL of the track's own page, if available.
    public let url: String?

    /// The duration formatted as `"M:SS"`.
    public var formattedDuration: String {
        guard let duration else { return "0:00" }
        let total = Int(duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    public init(
        id: Int, trackNumber: Int?, title: String, artist: String?, duration: TimeInterval?,
        streamURL: String?, isStreamable: Bool, isDownloadable: Bool, hasLyrics: Bool,
        lyrics: String?, playCount: Int?, url: String?
    ) {
        self.id = id
        self.trackNumber = trackNumber
        self.title = title
        self.artist = artist
        self.duration = duration
        self.streamURL = streamURL
        self.isStreamable = isStreamable
        self.isDownloadable = isDownloadable
        self.hasLyrics = hasLyrics
        self.lyrics = lyrics
        self.playCount = playCount
        self.url = url
    }
}

/// A purchasable physical/merch package for a release (vinyl, CD, cassette…).
public struct BandcampPackage: Sendable, Identifiable {

    /// The package ID.
    public let id: Int?

    /// The package title.
    public let title: String?

    /// The package type name (e.g. `"Vinyl LP"`, `"Compact Disc"`, `"T-Shirt/Apparel"`).
    public let typeName: String?

    /// The price.
    public let price: Double?

    /// The currency code.
    public let currency: String?

    /// The package description.
    public let description: String?

    /// The edition size, if a limited run.
    public let editionSize: Int?

    public init(
        id: Int?, title: String?, typeName: String?, price: Double?,
        currency: String?, description: String?, editionSize: Int?
    ) {
        self.id = id
        self.title = title
        self.typeName = typeName
        self.price = price
        self.currency = currency
        self.description = description
        self.editionSize = editionSize
    }
}

/// A Bandcamp release — an album or a single track — with its full metadata.
///
/// Extracted from the page's embedded `data-tralbum` / `data-band` JSON.
///
/// ```swift
/// let release = try await BandcampMetadata.release(
///     "https://c418.bandcamp.com/album/minecraft-volume-alpha"
/// )
/// print("\(release.artist) – \(release.title) (\(release.tracks.count) tracks)")
/// for t in release.tracks {
///     print("\(t.trackNumber ?? 0). \(t.title) [\(t.formattedDuration)] \(t.streamURL ?? "")")
/// }
/// ```
public struct BandcampRelease: Sendable, Identifiable {

    /// The Bandcamp release ID.
    public let id: Int

    /// The item type: `"album"` or `"track"`.
    public let itemType: String

    /// The canonical release URL.
    public let url: String

    /// The release title.
    public let title: String

    /// The release artist.
    public let artist: String

    /// The artist/band ID.
    public let artistID: Int?

    /// The release date.
    public let releaseDate: Date?

    /// The "about" description text.
    public let about: String?

    /// The credits text.
    public let credits: String?

    /// The minimum price (`0` for free / pure name-your-price).
    public let minimumPrice: Double?

    /// The currency code (e.g. `"USD"`).
    public let currency: String?

    /// Whether the release is name-your-price.
    public let isNameYourPrice: Bool

    /// The artwork ID; build a URL with ``artworkURL(size:)``.
    public let artworkID: Int?

    /// The genre/mood tags on the release.
    public let tags: [String]

    /// The tracklist.
    public let tracks: [BandcampTrack]

    /// Purchasable physical/merch packages (vinyl, CD…).
    public let packages: [BandcampPackage]

    /// Whether the release has a video.
    public let hasVideo: Bool

    /// Whether the release is a pre-order.
    public let isPreorder: Bool

    /// The UPC/barcode, if set.
    public let upc: String?

    // MARK: - Computed

    /// The number of tracks.
    public var trackCount: Int { tracks.count }

    /// Whether this is a single-track release.
    public var isSingleTrack: Bool { itemType == "track" }

    /// The total running time of all tracks, in seconds.
    public var totalDuration: TimeInterval { tracks.reduce(0) { $0 + ($1.duration ?? 0) } }

    /// An artwork URL at the given size (defaults to ``BandcampImageSize/large``).
    public func artworkURL(size: BandcampImageSize = .large) -> String? {
        artworkID.map { size.artworkURL(artID: $0) }
    }

    public init(
        id: Int, itemType: String, url: String, title: String, artist: String, artistID: Int?,
        releaseDate: Date?, about: String?, credits: String?, minimumPrice: Double?, currency: String?,
        isNameYourPrice: Bool, artworkID: Int?, tags: [String], tracks: [BandcampTrack],
        packages: [BandcampPackage], hasVideo: Bool, isPreorder: Bool, upc: String?
    ) {
        self.id = id
        self.itemType = itemType
        self.url = url
        self.title = title
        self.artist = artist
        self.artistID = artistID
        self.releaseDate = releaseDate
        self.about = about
        self.credits = credits
        self.minimumPrice = minimumPrice
        self.currency = currency
        self.isNameYourPrice = isNameYourPrice
        self.artworkID = artworkID
        self.tags = tags
        self.tracks = tracks
        self.packages = packages
        self.hasVideo = hasVideo
        self.isPreorder = isPreorder
        self.upc = upc
    }
}
