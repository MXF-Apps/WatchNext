import Foundation
import Testing
@testable import WatchNextCore

@Suite("Erase all data")
struct EraseDataTests {
    @Test("The configuration store forgets what was saved")
    func configurationStoreRemoveAll() async throws {
        let suite = "WatchNextTests.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let store = AppGroupConfigurationStore(appGroupIdentifier: suite)
        try await store.save(ServiceConfiguration(recentLookbackDays: 3, demoMode: true))
        #expect(await store.load().demoMode)

        await store.removeAll()

        let restored = await store.load()
        #expect(restored == ServiceConfiguration())
        #expect(UserDefaults(suiteName: suite)?.dictionaryRepresentation().keys.contains("WatchNext.ServiceConfiguration") == false)
    }

    @Test("The hidden list is emptied")
    func hiddenItemsRemoveAll() async throws {
        let suite = "WatchNextTests.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let store = HiddenItemStore(appGroupIdentifier: suite)
        try await store.hide(contentsOf: [.item(id: "movie:1"), .series(sonarrSeriesID: 10)])
        #expect(await store.hidden().count == 2)

        await store.removeAll()

        #expect(await store.hidden().isEmpty)
    }

    @Test("The feed cache file is deleted, and deleting twice is fine")
    func cacheRemove() async throws {
        let fileURL = URL.temporaryDirectory.appending(path: "watchnext-\(UUID().uuidString).json")
        let cache = WatchNextCache(fileURL: fileURL)
        try await cache.saveSuccessful(WatchNextFeed(ready: [
            MediaFeedItem(id: "movie:1", kind: .movie, title: "Movie", availability: .ready)
        ]))
        #expect(FileManager.default.fileExists(atPath: fileURL.path()))

        try await cache.remove()

        #expect(FileManager.default.fileExists(atPath: fileURL.path()) == false)
        #expect(await cache.load() == .empty)
        try await cache.remove()
    }
}
