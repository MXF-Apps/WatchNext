import Foundation

public struct MediaFeedItem: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let kind: MediaKind
    public let title: String
    public let subtitle: String?
    public let artworkURL: URL?
    public let artworkCacheKey: String?
    public let availability: AvailabilityState
    public let releaseDate: Date?
    public let importedDate: Date?
    public let isWatched: Bool?
    public let playbackProgress: Double?
    public let qualityDescription: String?
    public let sourceIDs: SourceIdentifiers
    public let seasonNumber: Int?
    public let episodeNumber: Int?
    /// Set by `WatchNextFeed.collapsingSeasons()`: how many later episodes of
    /// the same season this row stands in for. Never stored in the cache.
    public var collapsedEpisodeCount: Int?

    public init(
        id: String,
        kind: MediaKind,
        title: String,
        subtitle: String? = nil,
        artworkURL: URL? = nil,
        artworkCacheKey: String? = nil,
        availability: AvailabilityState,
        releaseDate: Date? = nil,
        importedDate: Date? = nil,
        isWatched: Bool? = nil,
        playbackProgress: Double? = nil,
        qualityDescription: String? = nil,
        sourceIDs: SourceIdentifiers = .init(),
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        collapsedEpisodeCount: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.artworkURL = artworkURL
        self.artworkCacheKey = artworkCacheKey
        self.availability = availability
        self.releaseDate = releaseDate
        self.importedDate = importedDate
        self.isWatched = isWatched
        self.playbackProgress = playbackProgress
        self.qualityDescription = qualityDescription
        self.sourceIDs = sourceIDs
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.collapsedEpisodeCount = collapsedEpisodeCount
    }
}
