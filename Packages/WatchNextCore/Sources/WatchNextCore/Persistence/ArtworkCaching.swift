public protocol ArtworkCaching: Sendable {
    func cacheArtwork(
        for feed: WatchNextFeed,
        configuration: ServiceConfiguration,
        credentials: [CredentialKey: String]
    ) async
}
