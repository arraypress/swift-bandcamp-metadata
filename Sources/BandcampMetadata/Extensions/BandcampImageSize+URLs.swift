//
//  BandcampImageSize+URLs.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//
//  The size vocabulary's URL builders, delegating into Support where
//  the scheme lives.
//

import Foundation

extension BandcampImageSize {

    /// Builds an album/track **artwork** URL for an `art_id` (uses the `a` prefix).
    func artworkURL(artID: Int) -> String {
        ImageURL.artwork(artID: artID, size: self)
    }

    /// Builds an **artist/band image** URL for an `image_id`.
    func imageURL(imageID: Int) -> String {
        ImageURL.image(imageID: imageID, size: self)
    }
}
