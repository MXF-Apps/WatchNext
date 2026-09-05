public struct SourceSnapshot: Sendable {
    public let sonarrEpisodes: [SonarrEpisode]
    public let radarrMovies: [RadarrMovie]
    public let jellyfinItems: [JellyfinMediaItem]

    public init(
        sonarrEpisodes: [SonarrEpisode],
        radarrMovies: [RadarrMovie],
        jellyfinItems: [JellyfinMediaItem]
    ) {
        self.sonarrEpisodes = sonarrEpisodes
        self.radarrMovies = radarrMovies
        self.jellyfinItems = jellyfinItems
    }
}
