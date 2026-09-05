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
}
