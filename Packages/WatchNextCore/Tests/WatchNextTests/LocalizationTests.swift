import Foundation
import Testing
@testable import WatchNextCore

struct LocalizationTests {
    @Test(arguments: ["All", "all", "ALL", "Movies", "movies", "Shows", "shows"])
    func legacyWidgetChoicesRemainReadable(_ storedValue: String) throws {
        let filter = try #require(FeedKindFilter(storedValue: storedValue))
        #expect(filter.rawValue == storedValue.lowercased())
    }

    @Test(arguments: [nil, "", "Films", "Séries", "unknown"] as [String?])
    func displayTranslationsAreNotStorageIdentifiers(_ storedValue: String?) {
        #expect(FeedKindFilter(storedValue: storedValue) == nil)
    }

    @Test
    func moviesShowNoSubtitleWhateverTheCacheHolds() throws {
        let original = MediaFeedItem(
            id: "movie:1", kind: .movie, title: "Paper Meridian",
            subtitle: "Movie", availability: .ready
        )
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(MediaFeedItem.self, from: data)
        #expect(restored.subtitle == "Movie")
        #expect(restored.localizedSubtitle == nil)
        #expect(restored.title == "Paper Meridian")
        let encoded = try #require(String(data: data, encoding: .utf8))
        #expect(encoded.contains("localizedSubtitle") == false)
    }

    @Test
    func episodeTitlesRemainServerContent() {
        let episode = MediaFeedItem(
            id: "episode:1", kind: .episode, title: "Harbor Lights",
            subtitle: "S02E01 — North Pier", availability: .ready
        )
        #expect(episode.localizedSubtitle == "S02E01 — North Pier")
    }
}
