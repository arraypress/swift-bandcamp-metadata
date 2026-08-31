//
//  ImageURL.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//
//  Bandcamp's image URL scheme in one place: f4.bcbits.com, a numeric
//  size suffix, and an `a` prefix that artwork takes but artist images
//  do not. Pure functions, pinned to exact strings.
//

import Foundation

/// Assembly of Bandcamp image URLs.
enum ImageURL {

    /// An album/track artwork URL for an `art_id` (uses the `a` prefix).
    static func artwork(artID: Int, size: BandcampImageSize) -> String {
        "https://f4.bcbits.com/img/a\(artID)_\(size.rawValue).jpg"
    }

    /// An artist/band image URL for an `image_id`.
    static func image(imageID: Int, size: BandcampImageSize) -> String {
        "https://f4.bcbits.com/img/\(imageID)_\(size.rawValue).jpg"
    }
}
