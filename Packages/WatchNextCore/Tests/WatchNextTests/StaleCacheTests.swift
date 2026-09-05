import Foundation
import Testing
@testable import WatchNextCore

@Suite("Stale cache behavior")
struct StaleCacheTests {
    @Test("Failed refresh preserves last successful content")
    func failedRefreshPreservesCache() async throws {
        let fileURL = URL.temporaryDirectory.appending(path: "watchnext-\(UUID().uuidString).json")
        let cache = WatchNextCache(fileURL: fileURL)
        let cachedItem = MediaFeedItem(
            id: "movie:cached",
            kind: .movie,
            title: "Cached Movie",
            availability: .ready
        )
        try await cache.saveSuccessful(WatchNextFeed(ready: [cachedItem]))
        let service = WatchNextFeedService(
            configurationStore: TestConfigurationStore(),
            sourceLoader: FailingSourceLoader(),
            cache: cache,
            artworkCache: nil
        )

        do {
            _ = try await service.refresh()
            Issue.record("Expected refresh to fail.")
        } catch NetworkError.invalidResponse {
            // Expected.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let stale = await cache.load()
        #expect(stale.ready.map(\.id) == ["movie:cached"])
        #expect(stale.lastSuccessfulRefresh != nil)
        #expect(stale.lastRefreshError != nil)
    }
}

private actor TestConfigurationStore: ConfigurationStoring {
    func load() -> ServiceConfiguration { ServiceConfiguration() }
    func save(_ configuration: ServiceConfiguration) {}
}

private struct FailingSourceLoader: SourceLoading {
    func load(configuration: ServiceConfiguration) async throws -> SourceSnapshot {
        throw NetworkError.invalidResponse
    }

    func credentials() async throws -> [CredentialKey: String] { [:] }
}
