//
//  BandcampArtist.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A release entry in an artist's or label's discography.
public struct BandcampReleaseSummary: Sendable, Identifiable {

    /// The release ID.
    public let id: Int

    /// The release title.
    public let title: String

    /// The credited artist string.
    public let artist: String?

    /// The absolute release URL.
    public let url: String

    /// The artwork ID; build a URL with ``artworkURL(size:)``.
    public let artworkID: Int?

    /// The item type: `"album"` or `"track"`.
    public let type: String

    /// An artwork URL at the given size (defaults to ``BandcampImageSize/medium``).
    public func artworkURL(size: BandcampImageSize = .medium) -> String? {
        artworkID.map { size.artworkURL(artID: $0) }
    }

    public init(id: Int, title: String, artist: String?, url: String, artworkID: Int?, type: String) {
        self.id = id
        self.title = title
        self.artist = artist
        self.url = url
        self.artworkID = artworkID
        self.type = type
    }
}

/// A Bandcamp artist or label, with its discography.
///
/// ```swift
/// let artist = try await BandcampMetadata.artist("https://c418.bandcamp.com")
/// print("\(artist.name) — \(artist.location ?? "")")
/// for release in artist.discography {
///     print("• \(release.title)")
/// }
/// ```
public struct BandcampArtist: Sendable, Identifiable {

    /// The Bandcamp band/artist ID.
    public let id: Int

    /// The artist or label name.
    public let name: String

    /// The Bandcamp subdomain (e.g. `"c418"`).
    public let subdomain: String?

    /// The artist's Bandcamp URL.
    public let url: String?

    /// The location, if shown (e.g. `"Germany"`).
    public let location: String?

    /// The biography text, if available.
    public let bio: String?

    /// Whether this account is a label (rather than a single artist).
    public let isLabel: Bool

    /// The artist image ID; build a URL with ``imageURL(size:)``.
    public let imageID: Int?

    /// The artist's discography (albums and tracks).
    public let discography: [BandcampReleaseSummary]

    /// An artist-image URL at the given size (defaults to ``BandcampImageSize/medium``).
    public func imageURL(size: BandcampImageSize = .medium) -> String? {
        imageID.map { size.imageURL(imageID: $0) }
    }

    public init(
        id: Int, name: String, subdomain: String?, url: String?, location: String?,
        bio: String?, isLabel: Bool, imageID: Int?, discography: [BandcampReleaseSummary]
    ) {
        self.id = id
        self.name = name
        self.subdomain = subdomain
        self.url = url
        self.location = location
        self.bio = bio
        self.isLabel = isLabel
        self.imageID = imageID
        self.discography = discography
    }
}
