//
//  BandcampImageSize.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A Bandcamp image size, used to build artwork / artist-image URLs.
///
/// Bandcamp serves images from `f4.bcbits.com` with a numeric size suffix.
public enum BandcampImageSize: Int, Sendable {
    /// The original, full-resolution image.
    case original = 0
    /// 1200 × 1200.
    case large = 10
    /// 700 × 700.
    case medium = 16
    /// 350 × 350.
    case small = 2
    /// 150 × 150 (thumbnail).
    case thumbnail = 7
}
