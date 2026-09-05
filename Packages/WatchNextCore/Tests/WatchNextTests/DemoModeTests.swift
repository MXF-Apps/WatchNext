import Foundation
import Testing
@testable import WatchNextCore

@Suite("Demo mode")
struct DemoModeTests {
    private let now = ISO8601DateFormatter().date(from: "2026-09-05T12:00:00Z")!

    @Test("The demo catalog builds a feed with every state the app can show")
    func demoFeedShape() {
        let snapshot = DemoSourceLoader.snapshot(now: now)
        let feed = WatchNextFeedBuilder()
            .build(snapshot: snapshot, configuration: ServiceConfiguration(), now: now)
            .collapsingSeasons()

        #expect(feed.ready.count == 6, "a folded season, a partially watched episode, and four movies")
        let folded = feed.ready.first { $0.title == "Harbor Lights" }
        #expect(folded?.collapsedEpisodeCount == 5)
        #expect(folded?.episodeNumber == 1)
        #expect(feed.ready.contains { $0.title == "The Long Static" && $0.playbackProgress == 0.4 })

        #expect(feed.comingSoon.first?.title == "Saltmarsh")
        #expect(feed.comingSoon.first?.availability == .awaitingDownload)
        #expect(feed.comingSoon.filter { $0.availability == .comingSoon }.count == 4)
    }

    @Test("Every demo item has a bundled poster under the key the builder derives")
    func postersResolve() {
        let snapshot = DemoSourceLoader.snapshot(now: now)
        let feed = WatchNextFeedBuilder().build(snapshot: snapshot, configuration: ServiceConfiguration(), now: now)
        let assigned = Set(DemoSourceLoader.posterAssignments.map(\.cacheKey))
        for item in feed.ready + feed.comingSoon {
            let key = try? #require(item.artworkCacheKey)
            #expect(key.map(assigned.contains) == true, "no poster assigned for \(item.id)")
        }
        for slug in Set(DemoSourceLoader.posterAssignments.map(\.slug)) {
            #expect(DemoSourceLoader.posterURL(for: slug) != nil, "missing poster resource \(slug)")
        }
    }

    @Test("Settings saved before demo mode existed decode with it off")
    func legacyConfigurationDecodes() throws {
        let legacy = """
        {"sonarrBaseURL":"http://example.test:8989","recentLookbackDays":14,"futureWindowDays":7}
        """
        let configuration = try JSONDecoder().decode(ServiceConfiguration.self, from: Data(legacy.utf8))
        #expect(configuration.demoMode == false)
        #expect(configuration.futureWindowDays == 7)

        let roundTrip = try JSONDecoder().decode(
            ServiceConfiguration.self,
            from: JSONEncoder().encode(ServiceConfiguration(demoMode: true))
        )
        #expect(roundTrip.demoMode)
    }

    @Test("The switching loader follows the configuration flag")
    func switching() async throws {
        let loader = ModeSwitchingSourceLoader(live: FailingLoader(), demo: DemoSourceLoader())
        let demo = try await loader.load(configuration: ServiceConfiguration(demoMode: true))
        #expect(demo.radarrMovies.isEmpty == false)
        await #expect(throws: NetworkError.invalidResponse) {
            try await loader.load(configuration: ServiceConfiguration(demoMode: false))
        }
    }
}

private struct FailingLoader: SourceLoading {
    func load(configuration: ServiceConfiguration) async throws -> SourceSnapshot { throw NetworkError.invalidResponse }
    func credentials() async throws -> [CredentialKey: String] { [:] }
}
