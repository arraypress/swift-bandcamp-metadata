# Swift Bandcamp Metadata

A Swift library for extracting rich metadata from [Bandcamp](https://bandcamp.com) releases and artists — including **streaming/preview URLs**, tracklists, prices, artwork, tags, physical packages, and full discographies. No API key required.

> Bandcamp has no public API. This library reads the JSON that Bandcamp embeds in every page (`data-tralbum` / `data-band` — the same data that powers its embed player). It is therefore a scraper: reliable (that payload has been stable for years) but against Bandcamp's Terms of Service. Use responsibly.

## Features

- 💿 **Releases** — title, artist, release date, description, credits, minimum price + currency, UPC, genre tags
- 🎧 **Tracklist with stream URLs** — each track's title, duration, **128 kbps stream/preview URL**, lyrics, downloadable flag, play count
- 🖼️ **Artwork** — build URLs at any size via `BandcampImageSize`
- 📦 **Physical packages** — vinyl / CD / merch with price, type, edition size
- 👤 **Artists & labels** — name, location, bio, image, and full discography
- 🔎 **Search** — find artists, albums, tracks, and labels; filter by type; each hit links straight into `release`/`artist`
- 🔓 **Keyless** — no API, no token
- 🍎 **Cross-platform** — macOS, iOS, tvOS, watchOS · Swift 6 · async/await
- 🛡️ **Typed error handling**

Rounds out the music set: **Discogs** (records) · **MusicBrainz** (canonical) · **iTunes** (Apple) · **Reverb** (gear) · **Bandcamp** (indie/direct + streams).

## Usage

```swift
import BandcampMetadata

// A release (album or track) — everything, including stream URLs
let release = try await BandcampMetadata.release(
    "https://c418.bandcamp.com/album/minecraft-volume-alpha"
)
print("\(release.artist) – \(release.title) (\(release.trackCount) tracks)")
print("\(release.minimumPrice ?? 0) \(release.currency ?? "") · tags: \(release.tags.joined(separator: ", "))")
print(release.artworkURL(size: .large) ?? "")

for t in release.tracks {
    print("\(t.trackNumber ?? 0). \(t.title) [\(t.formattedDuration)] — \(t.streamURL ?? "no stream")")
}
for pkg in release.packages {
    print("📦 \(pkg.typeName ?? "") — \(pkg.price ?? 0) \(pkg.currency ?? "")")
}

// An artist / label + discography
let artist = try await BandcampMetadata.artist("https://c418.bandcamp.com")
print("\(artist.name) — \(artist.discography.count) releases")
for r in artist.discography { print("• \(r.title) — \(r.url)") }

// Search (filter by type: .all / .artists / .albums / .tracks / .labels)
let results = try await BandcampMetadata.search("aphex twin", type: .albums)
for hit in results {
    print("[\(hit.type)] \(hit.name) — \(hit.artist ?? "") \(hit.url ?? "")")
    // hit.url feeds straight into release(_:) / artist(_:)
}
```

## Models

| Type | Description |
|------|-------------|
| `BandcampRelease` | `id`, `itemType`, `title`, `artist`, `releaseDate`, `about`, `credits`, `minimumPrice`/`currency`/`isNameYourPrice`, `artworkID` + `artworkURL(size:)`, `tags`, `tracks`, `packages`, `hasVideo`, `isPreorder`, `upc`, plus `trackCount`/`totalDuration` |
| `BandcampTrack` | `id`, `trackNumber`, `title`, `artist`, `duration`/`formattedDuration`, `streamURL`, `isStreamable`, `isDownloadable`, `hasLyrics`, `lyrics`, `playCount`, `url` |
| `BandcampPackage` | `title`, `typeName`, `price`, `currency`, `description`, `editionSize` |
| `BandcampArtist` | `id`, `name`, `subdomain`, `url`, `location`, `bio`, `isLabel`, `imageID` + `imageURL(size:)`, `discography` |
| `BandcampReleaseSummary` | `id`, `title`, `artist`, `url`, `artworkID` + `artworkURL(size:)`, `type` |
| `BandcampSearchResult` | `id`, `type`, `name`, `artist`, `url`, `artworkID`/`imageID` + `imageURL(size:)`, `location`, `genre`, `tags`, `isLabel`, `isRelease` |
| `BandcampSearchType` / `BandcampResultType` | Search filter + result-type enums |
| `BandcampImageSize` | `original`/`large`/`medium`/`small`/`thumbnail` |
| `BandcampMetadataError` | Typed errors with `errorDescription` |

## Testing

```bash
swift test                             # offline unit tests (fixtures)
BANDCAMP_LIVE_TESTS=1 swift test        # + live network tests
```

## License

MIT

## Author

David Sherlock
