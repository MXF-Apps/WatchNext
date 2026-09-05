import Foundation
import Testing
@testable import WatchNextCore

@Suite("Hidden items")
struct HiddenItemsTests {
    private let now = ISO8601DateFormatter().date(from: "2026-09-04T12:00:00Z")!

    private func fixtureFeed() throws -> WatchNextFeed {
        let fixture = try FixtureSnapshot.load()
        return WatchNextFeedBuilder().build(
            snapshot: fixture.sourceSnapshot,
            configuration: ServiceConfiguration(),
            now: now
        )
    }

    @Test("Hiding an item removes only that item")
    func hideSingleItem() throws {
        let feed = try fixtureFeed()
        let visible = feed.hiding([.item(id: "movie:20")])
        #expect(visible.ready.map(\.id) == ["episode:105"])
        #expect(visible.comingSoon == feed.comingSoon)
        #expect(feed.hiddenItems(matching: [.item(id: "movie:20")]).map(\.id) == ["movie:20"])
    }

    @Test("Hiding a series removes ready and upcoming episodes of that series")
    func hideSeries() throws {
        let feed = try fixtureFeed()
        let severance = try #require(feed.ready.first { $0.id == "episode:105" })
        let seriesKey = try #require(severance.seriesHideKey)
        #expect(seriesKey == .series(sonarrSeriesID: 10))

        let visible = feed.hiding([seriesKey])
        #expect(visible.allItems.contains { $0.sourceIDs.sonarrSeriesID == 10 } == false)
        #expect(visible.ready.map(\.id) == ["movie:20"])
        #expect(visible.allItems.count < feed.allItems.count)
    }

    @Test("Kind filter keeps only movies or only shows")
    func kindFilter() throws {
        let feed = try fixtureFeed()
        #expect(feed.filtering(.movies).allItems.allSatisfy { $0.kind == .movie })
        #expect(feed.filtering(.shows).allItems.allSatisfy { $0.kind == .episode })
        #expect(feed.filtering(.all) == feed)
        #expect(feed.filtering(.movies).allItems.count + feed.filtering(.shows).allItems.count == feed.allItems.count)
    }

    @Test("Store round-trips entries and prunes those absent from the feed")
    func storePrunes() async throws {
        let suite = "WatchNextTests.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let store = HiddenItemStore(appGroupIdentifier: suite)

        try await store.hide(.item(id: "movie:20"))
        try await store.hide(.series(sonarrSeriesID: 10))
        try await store.hide(.item(id: "movie:gone"))
        try await store.hide(.series(sonarrSeriesID: 999))
        #expect(await store.hidden().count == 4)

        let remaining = try await store.prune(keeping: try fixtureFeed())
        #expect(remaining == [.item(id: "movie:20"), .series(sonarrSeriesID: 10)])
        #expect(await store.hidden() == remaining)

        try await store.unhide([.item(id: "movie:20"), .item(id: "never-hidden")])
        #expect(await store.hidden() == [.series(sonarrSeriesID: 10)])
    }

    @Test("Batch hide adds every new entry in one write and ignores duplicates")
    func batchHide() async throws {
        let suite = "WatchNextTests.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let store = HiddenItemStore(appGroupIdentifier: suite)

        try await store.hide(.item(id: "movie:1"))
        try await store.hide(contentsOf: [.item(id: "movie:1"), .item(id: "movie:2"), .series(sonarrSeriesID: 10)])
        #expect(await store.hidden() == [.item(id: "movie:1"), .item(id: "movie:2"), .series(sonarrSeriesID: 10)])

        try await store.unhide([.item(id: "movie:1"), .item(id: "movie:2")])
        #expect(await store.hidden() == [.series(sonarrSeriesID: 10)])
    }

    @Test("Successful refresh prunes stale hidden entries and keeps the cache unfiltered")
    func refreshPrunes() async throws {
        let suite = "WatchNextTests.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let store = HiddenItemStore(appGroupIdentifier: suite)
        try await store.hide(.item(id: "movie:20"))
        try await store.hide(.item(id: "movie:watched-long-ago"))

        let fileURL = URL.temporaryDirectory.appending(path: "watchnext-\(UUID().uuidString).json")
        let service = WatchNextFeedService(
            configurationStore: FixedConfigurationStore(),
            sourceLoader: FixtureSourceLoader(),
            cache: WatchNextCache(fileURL: fileURL),
            artworkCache: nil,
            hiddenItemStore: store
        )

        let feed = try await service.refresh()
        #expect(feed.ready.map(\.id).contains("movie:20"), "cache stays unfiltered")
        #expect(await store.hidden() == [.item(id: "movie:20")])
    }
}

private actor FixedConfigurationStore: ConfigurationStoring {
    func load() -> ServiceConfiguration { ServiceConfiguration() }
    func save(_ configuration: ServiceConfiguration) {}
}

private struct FixtureSourceLoader: SourceLoading {
    func load(configuration: ServiceConfiguration) async throws -> SourceSnapshot {
        try FixtureSnapshot.load().sourceSnapshot
    }

    func credentials() async throws -> [CredentialKey: String] { [:] }
}
