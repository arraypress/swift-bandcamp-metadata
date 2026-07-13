//
//  BandcampExtractor.swift
//  BandcampMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Pulls the embedded JSON and supplementary bits out of Bandcamp page HTML.
///
/// Bandcamp encodes JSON into HTML attributes (`data-tralbum`, `data-band`,
/// `data-client-items`), where quotes appear as `&quot;` etc. This extracts the
/// attribute, decodes the entities, and parses the JSON.
enum BandcampExtractor {

    /// Extracts and parses a JSON **object** from a `data-…` attribute.
    static func jsonObject(attribute name: String, in html: String) -> [String: Any]? {
        guard let raw = attributeValue(name, in: html),
              let data = decodeEntities(raw).data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    /// Extracts and parses a JSON **array** from a `data-…` attribute.
    static func jsonArray(attribute name: String, in html: String) -> [[String: Any]]? {
        guard let raw = attributeValue(name, in: html),
              let data = decodeEntities(raw).data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
    }

    /// The genre/mood tags on a release page.
    static func tags(in html: String) -> [String] {
        matches(#"class="tag"[^>]*>\s*([^<]+?)\s*<"#, in: html)
            .map { decodeEntities($0) }
            .filter { !$0.isEmpty }
    }

    /// The currency code embedded in the page (e.g. `"USD"`), if present.
    ///
    /// Release pages expose it as schema.org `priceCurrency`; other pages use a
    /// plain `currency` field.
    static func currency(in html: String) -> String? {
        firstMatch(#""priceCurrency"\s*:\s*"([A-Z]{3})""#, in: html)
            ?? firstMatch(#""currency"\s*:\s*"([A-Z]{3})""#, in: html)
    }

    /// The meta-description text (used as a fallback for an artist bio).
    static func metaDescription(in html: String) -> String? {
        guard let raw = firstMatch(#"<meta name="description" content="([^"]*)""#, in: html) else { return nil }
        let text = decodeEntities(raw).trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    /// The artist location shown on an artist page, if present.
    static func location(in html: String) -> String? {
        guard let raw = firstMatch(#"class="[^"]*location[^"]*"[^>]*>\s*([^<]+?)\s*<"#, in: html) else { return nil }
        let text = decodeEntities(raw).trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    // MARK: - Helpers

    /// Extracts the raw (still entity-encoded) value of an HTML attribute.
    private static func attributeValue(_ name: String, in html: String) -> String? {
        firstMatch("\(name)=\"([^\"]*)\"", in: html)
    }

    /// Decodes the HTML entities Bandcamp uses inside attribute-encoded JSON.
    private static func decodeEntities(_ text: String) -> String {
        var out = text
        for (entity, char) in [
            ("&quot;", "\""), ("&#34;", "\""), ("&#039;", "'"), ("&#39;", "'"),
            ("&apos;", "'"), ("&gt;", ">"), ("&lt;", "<"), ("&nbsp;", " ")
        ] {
            out = out.replacingOccurrences(of: entity, with: char)
        }
        out = decodeNumeric(out)
        // &amp; must be decoded last so it can't double-decode.
        out = out.replacingOccurrences(of: "&amp;", with: "&")
        return out
    }

    private static func decodeNumeric(_ input: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"&#(x?)([0-9a-fA-F]+);"#) else { return input }
        let ns = input as NSString
        var result = input
        for match in regex.matches(in: input, range: NSRange(location: 0, length: ns.length)).reversed() {
            let isHex = ns.substring(with: match.range(at: 1)) == "x"
            let digits = ns.substring(with: match.range(at: 2))
            guard let code = UInt32(digits, radix: isHex ? 16 : 10),
                  let scalar = Unicode.Scalar(code),
                  let range = Range(match.range, in: result) else { continue }
            result.replaceSubrange(range, with: String(Character(scalar)))
        }
        return result
    }

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }

    private static func matches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap {
            Range($0.range(at: 1), in: text).map { String(text[$0]) }
        }
    }
}
