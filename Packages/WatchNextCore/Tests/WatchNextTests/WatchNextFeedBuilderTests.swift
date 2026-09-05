import Foundation
import Testing
@testable import WatchNextCore

@Suite("WatchNext feed filtering")
struct WatchNextFeedBuilderTests {
    private let now = ISO8601DateFormatter().date(from: "2026-09-04T12:00:00Z")!

    @Test("Ready items include recent, present, unwatched imports")
    func readyFiltering() throws {
        let fixture = try FixtureSnapshot.load()
        let feed = WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(),
            now: now
        )
        #expect(feed.ready.map(\.id) == ["movie:20", "episode:105"])
        #expect(feed.ready.first?.playbackProgress == 0.42)
    }

    @Test("Watched Jellyfin items disappear")
    func watchedFiltering() throws {
        let fixture = try FixtureSnapshot.load()
        let watched = fixture.jellyfinItems.map { item in
            JellyfinMediaItem(
                id: item.id,
                kind: item.kind,
                name: item.name,
                seriesName: item.seriesName,
                productionYear: item.productionYear,
                seasonNumber: item.seasonNumber,
                episodeNumber: item.episodeNumber,
                isPlayed: true,
                playbackProgress: item.playbackProgress,
                providerIDs: item.providerIDs,
                seriesProviderIDs: item.seriesProviderIDs
            )
        }
        let feed = WatchNextFeedBuilder().build(
            snapshot: SourceSnapshot(
                sonarrEpisodes: fixture.sonarrEpisodes,
                radarrMovies: fixture.radarrMovies,
                jellyfinItems: watched
            ),
            configuration: ServiceConfiguration(),
            now: now
        )
        #expect(feed.ready.isEmpty)
    }

    @Test("A recent window of 0 disables the import-date cutoff")
    func unlimitedRecentWindow() throws {
        let fixture = try FixtureSnapshot.load()
        let monthsLater = ISO8601DateFormatter().date(from: "2026-12-01T12:00:00Z")!
        let limited = WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(recentLookbackDays: 14),
            now: monthsLater
        )
        #expect(limited.ready.isEmpty)

        let unlimited = WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(recentLookbackDays: 0),
            now: monthsLater
        )
        #expect(unlimited.ready.map(\.id) == ["movie:20", "episode:105"])
    }

    @Test("A future window of 0 extends Coming Soon to a year ahead")
    func unlimitedFutureWindow() throws {
        let fixture = try FixtureSnapshot.load()
        let newYear = ISO8601DateFormatter().date(from: "2026-01-01T12:00:00Z")!
        let limited = WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(futureWindowDays: 14),
            now: newYear
        )
        #expect(limited.comingSoon.isEmpty)

        let unlimited = WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(futureWindowDays: 0),
            now: newYear
        )
        #expect(unlimited.comingSoon.map(\.id) == ["episode:106", "movie:21"])

        let configuration = ServiceConfiguration(futureWindowDays: 0)
        let horizon = configuration.futureEnd(now: newYear, calendar: Calendar(identifier: .gregorian))
        #expect(Calendar(identifier: .gregorian).dateComponents([.day], from: newYear, to: horizon).day == 365)
    }

    @Test("Aired or released but not imported items stay in Coming Soon as awaiting download")
    func awaitingDownload() throws {
        let fixture = try FixtureSnapshot.load()
        // Episode 106 aired 2026-09-10, movie 21 released 2026-09-12; neither has a file.
        let afterBoth = ISO8601DateFormatter().date(from: "2026-09-13T12:00:00Z")!
        let feed = WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(recentLookbackDays: 14),
            now: afterBoth
        )
        #expect(feed.comingSoon.map(\.id) == ["episode:106", "movie:21"], "soonest date first, aired items at the top")
        #expect(feed.comingSoon.map(\.availability) == [.awaitingDownload, .awaitingDownload])
        #expect(feed.ready.map(\.id).contains("episode:106") == false)

        // Only the movie is within a one-day window.
        let oneDay = WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(recentLookbackDays: 1),
            now: ISO8601DateFormatter().date(from: "2026-09-12T12:00:00Z")!
        )
        #expect(oneDay.comingSoon.map(\.id) == ["movie:21"])
        #expect(oneDay.comingSoon.first?.availability == .awaitingDownload)
    }

    @Test("Imports outside the recent window are excluded")
    func recentImportWindow() throws {
        let fixture = try FixtureSnapshot.load()
        let feed = WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(recentLookbackDays: 1),
            now: now
        )
        #expect(feed.ready.map(\.id) == ["movie:20"])
    }

    @Test("Future items respect window and monitored status")
    func futureWindow() throws {
        let fixture = try FixtureSnapshot.load()
        let narrow = WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(futureWindowDays: 5),
            now: now
        )
        let wide = WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(futureWindowDays: 14),
            now: now
        )
        #expect(narrow.comingSoon.isEmpty)
        #expect(wide.comingSoon.map(\.id) == ["episode:106", "movie:21"])
    }

    @Test("Ready sorts newest first and coming soon nearest first")
    func sorting() throws {
        let fixture = try FixtureSnapshot.load()
        let feed = WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(),
            now: now
        )
        #expect(feed.ready.map(\.id) == ["movie:20", "episode:105"])
        #expect(feed.comingSoon.map(\.id) == ["episode:106", "movie:21"])
    }

    @Test("Duplicate source records are eliminated")
    func duplicateElimination() throws {
        let fixture = try FixtureSnapshot.load()
        let duplicated = SourceSnapshot(
            sonarrEpisodes: fixture.sonarrEpisodes + fixture.sonarrEpisodes,
            radarrMovies: fixture.radarrMovies + fixture.radarrMovies,
            jellyfinItems: fixture.jellyfinItems
        )
        let feed = WatchNextFeedBuilder().build(
            snapshot: duplicated,
            configuration: ServiceConfiguration(),
            now: now
        )
        #expect(Set(feed.ready.map(\.id)).count == feed.ready.count)
        #expect(Set(feed.comingSoon.map(\.id)).count == feed.comingSoon.count)
    }
}
