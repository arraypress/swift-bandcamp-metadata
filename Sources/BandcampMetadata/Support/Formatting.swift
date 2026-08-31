//
//  Formatting.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//
//  Track durations as Bandcamp shows them: minutes and seconds, never
//  folding into hours — a 65-minute drone is "65:00". A pure function
//  so the rule is pinned directly.
//

import Foundation

/// Presentation formatting for derived, human-readable strings.
enum Formatting {

    /// Seconds as `"M:SS"`, minutes unbounded.
    static func trackDuration(seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
