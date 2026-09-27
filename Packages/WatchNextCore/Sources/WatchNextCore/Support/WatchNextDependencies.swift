public struct WatchNextDependencies: Sendable {
    public let configurationStore: AppGroupConfigurationStore
    public let credentialStore: KeychainCredentialStore
    public let cache: WatchNextCache
    public let feedService: WatchNextFeedService
    public let connectionService: WatchNextConnectionService
    public let hiddenItemStore: HiddenItemStore

    public init() {
        let configurationStore = AppGroupConfigurationStore()
        let credentialStore = KeychainCredentialStore()
        let cache = WatchNextCache()
        let hiddenItemStore = HiddenItemStore()
        self.configurationStore = configurationStore
        self.credentialStore = credentialStore
        self.cache = cache
        self.hiddenItemStore = hiddenItemStore
        self.feedService = WatchNextFeedService(
            configurationStore: configurationStore,
            sourceLoader: ModeSwitchingSourceLoader(live: LiveSourceLoader(credentialStore: credentialStore)),
            cache: cache,
            hiddenItemStore: hiddenItemStore
        )
        self.connectionService = WatchNextConnectionService(credentialStore: credentialStore)
    }

    public static let live = WatchNextDependencies()

    /// Removes everything WatchNext stored on this device: credentials in the
    /// Keychain, the feed cache and posters in the App Group container, the
    /// hidden list and the service configuration. Every store is attempted
    /// even if an earlier one fails; the first failure is rethrown at the end.
    /// Servers are never touched.
    public func eraseAllData() async throws {
        var firstError: (any Error)?
        func attempt(_ body: () async throws -> Void) async {
            do {
                try await body()
            } catch {
                firstError = firstError ?? error
            }
        }
        await attempt { try await credentialStore.removeAll() }
        await attempt { try await cache.remove() }
        await attempt { try ArtworkLocation.removeAll() }
        await attempt { await hiddenItemStore.removeAll() }
        await attempt { await configurationStore.removeAll() }
        if let firstError {
            logger.error("Erasing local data did not complete.", error: firstError, category: "Erase")
            throw firstError
        }
        logger.notice("Erased all local data.", category: "Erase")
    }
}
