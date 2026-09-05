import Foundation

public actor WatchNextFeedService {
    private let configurationStore: any ConfigurationStoring
    private let sourceLoader: any SourceLoading
    private let builder: any FeedBuilding
    private let cache: any FeedCaching
    private let artworkCache: (any ArtworkCaching)?
    private let hiddenItemStore: (any HiddenItemStoring)?

    public init(
        configurationStore: any ConfigurationStoring,
        sourceLoader: any SourceLoading,
        builder: any FeedBuilding = WatchNextFeedBuilder(),
        cache: any FeedCaching,
        artworkCache: (any ArtworkCaching)? = ArtworkCache(),
        hiddenItemStore: (any HiddenItemStoring)? = nil
    ) {
        self.configurationStore = configurationStore
        self.sourceLoader = sourceLoader
        self.builder = builder
        self.cache = cache
        self.artworkCache = artworkCache
        self.hiddenItemStore = hiddenItemStore
    }

    public func cachedFeed() async -> WatchNextFeed {
        await cache.load()
    }

    @discardableResult
    public func refresh() async throws -> WatchNextFeed {
        logger.info("Feed refresh started.", category: "Refresh")
        let configuration = await configurationStore.load()
        do {
            let snapshot = try await sourceLoader.load(configuration: configuration)
            var feed = builder.build(snapshot: snapshot, configuration: configuration, now: .now)
            let now = Date.now
            feed.lastSuccessfulRefresh = now
            feed.lastRefreshAttempt = now
            try await cache.saveSuccessful(feed)
            logger.info(
                "Feed built with \(feed.ready.count) ready and \(feed.comingSoon.count) upcoming items.",
                category: "Refresh"
            )
            if let hiddenItemStore {
                // The cache keeps the full feed; hidden entries are applied at
                // display time. Prune here so the list only ever references
                // media that is still in the feed.
                do {
                    try await hiddenItemStore.prune(keeping: feed)
                } catch {
                    logger.error("Could not prune hidden items.", error: error, category: "HiddenItems")
                }
            }
            if let artworkCache {
                let credentials = try await sourceLoader.credentials()
                await artworkCache.cacheArtwork(
                    for: feed,
                    configuration: configuration,
                    credentials: credentials
                )
            }
            logger.info("Feed refresh completed successfully.", category: "Refresh")
            return await cache.load()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            logger.error("Feed refresh failed.", error: error, category: "Refresh")
            do {
                try await cache.recordFailure(message)
            } catch {
                logger.error("Could not record refresh failure in the shared cache.", error: error, category: "Cache")
            }
            throw error
        }
    }
}
