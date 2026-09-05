public struct SourceIdentifiers: Codable, Hashable, Sendable {
    public var sonarrID: Int?
    public var sonarrSeriesID: Int?
    public var radarrID: Int?
    public var jellyfinID: String?
    public var tvdbID: String?
    public var tmdbID: String?
    public var imdbID: String?

    public init(
        sonarrID: Int? = nil,
        sonarrSeriesID: Int? = nil,
        radarrID: Int? = nil,
        jellyfinID: String? = nil,
        tvdbID: String? = nil,
        tmdbID: String? = nil,
        imdbID: String? = nil
    ) {
        self.sonarrID = sonarrID
        self.sonarrSeriesID = sonarrSeriesID
        self.radarrID = radarrID
        self.jellyfinID = jellyfinID
        self.tvdbID = tvdbID
        self.tmdbID = tmdbID
        self.imdbID = imdbID
    }
}
