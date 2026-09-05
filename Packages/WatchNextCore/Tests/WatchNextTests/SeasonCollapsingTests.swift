import Foundation
import Testing
@testable import WatchNextCore

@Suite("Season collapsing")
struct SeasonCollapsingTests {
    private func episode(
        _ id: Int,
        series: Int,
        season: Int,
        number: Int,
        imported: TimeInterval,
        progress: Double? = nil
    ) -> MediaFeedItem {
        MediaFeedItem(
            id: "episode:\(id)",
            kind: .episode,
            title: "Series \(series)",
            subtitle: EpisodeSubtitle.make(season: season, episode: number, title: "Episode \(number)"),
            availability: .ready,
            importedDate: Date(timeIntervalSinceReferenceDate: imported),
            playbackProgress: progress,
            sourceIDs: .init(sonarrID: id, sonarrSeriesID: series),
            seasonNumber: season,
            episodeNumber: number
        )
    }

    private let movie = MediaFeedItem(id: "movie:1", kind: .movie, title: "Movie", availability: .ready)

    @Test("A season folds into its earliest episode and keeps the group's place")
    func foldsSeason() {
        // Newest import first, as the builder sorts ready items.
        let ready = [
            episode(5, series: 10, season: 3, number: 5, imported: 500),
            movie,
            episode(3, series: 10, season: 3, number: 3, imported: 300, progress: 0.4),
            episode(4, series: 10, season: 3, number: 4, imported: 400),
            episode(9, series: 20, season: 1, number: 9, imported: 200)
        ]

        let collapsed = MediaFeedItem.collapsingSeasons(ready)

        #expect(collapsed.map(\.id) == ["episode:3", "movie:1", "episode:9"])
        #expect(collapsed[0].collapsedEpisodeCount == 2)
        #expect(collapsed[0].collapsedEpisodesDescription == "and 2 more")
        #expect(collapsed[0].collapsedEpisodesBadge == "×3")
        #expect(collapsed[0].playbackProgress == 0.4, "the surfaced episode keeps its own state")
        #expect(collapsed[1].collapsedEpisodeCount == nil)
        #expect(collapsed[2].collapsedEpisodeCount == nil, "a lone episode is not annotated")
    }

    @Test("Different seasons of one series stay separate")
    func separatesSeasons() {
        let ready = [
            episode(1, series: 10, season: 2, number: 1, imported: 300),
            episode(2, series: 10, season: 2, number: 2, imported: 200),
            episode(3, series: 10, season: 1, number: 1, imported: 100)
        ]
        let collapsed = MediaFeedItem.collapsingSeasons(ready)
        #expect(collapsed.map(\.id) == ["episode:1", "episode:3"])
        #expect(collapsed.map(\.collapsedEpisodeCount) == [1, nil])
    }

    @Test("Episodes without season data pass through")
    func passesThroughUnknownSeasons() {
        let legacy = MediaFeedItem(
            id: "episode:old",
            kind: .episode,
            title: "Legacy",
            availability: .ready,
            sourceIDs: .init(sonarrID: 1, sonarrSeriesID: 10)
        )
        let collapsed = MediaFeedItem.collapsingSeasons([legacy, legacy])
        #expect(collapsed.count == 2)
        #expect(collapsed.allSatisfy { $0.collapsedEpisodeCount == nil })
    }

    @Test("Hiding the surfaced episode reveals the next one")
    func hidingRevealsNext() {
        let feed = WatchNextFeed(ready: [
            episode(3, series: 10, season: 3, number: 3, imported: 300),
            episode(4, series: 10, season: 3, number: 4, imported: 400),
            episode(5, series: 10, season: 3, number: 5, imported: 500)
        ])
        let visible = feed.hiding([.item(id: "episode:3")]).collapsingSeasons()
        #expect(visible.ready.map(\.id) == ["episode:4"])
        #expect(visible.ready[0].collapsedEpisodeCount == 1)
    }

    @Test("Coming Soon keeps one row per episode; old caches still decode")
    func leavesUpcomingAlone() throws {
        let upcoming = [
            episode(1, series: 10, season: 4, number: 1, imported: 0),
            episode(2, series: 10, season: 4, number: 2, imported: 0)
        ]
        let feed = WatchNextFeed(comingSoon: upcoming).collapsingSeasons()
        #expect(feed.comingSoon.map(\.id) == ["episode:1", "episode:2"])
        #expect(feed.comingSoon.allSatisfy { $0.collapsedEpisodeCount == nil })

        // Old caches without season fields still decode.
        let legacyJSON = """
        {"id":"episode:7","kind":"episode","title":"T","availability":"ready","sourceIDs":{}}
        """
        let decoded = try JSONDecoder().decode(MediaFeedItem.self, from: Data(legacyJSON.utf8))
        #expect(decoded.seasonNumber == nil)
        #expect(decoded.collapsedEpisodeCount == nil)
    }
}
