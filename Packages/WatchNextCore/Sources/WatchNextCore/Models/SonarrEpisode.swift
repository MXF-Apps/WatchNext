import Foundation

public struct SonarrEpisode: Codable, Hashable, Sendable {
    public let id: Int
    public let seriesID: Int
    public let seriesTitle: String
    public let episodeTitle: String?
    public let seasonNumber: Int
    public let episodeNumber: Int
    public let monitored: Bool
    public let hasFile: Bool
    public let airDate: Date?
    public let importedDate: Date?
    public let quality: String?
    public let tvdbSeriesID: String?
    public let tvdbEpisodeID: String?
    public let tmdbSeriesID: String?
    public let artworkURL: URL?

    public init(
        id: Int,
        seriesID: Int,
        seriesTitle: String,
        episodeTitle: String?,
        seasonNumber: Int,
        episodeNumber: Int,
        monitored: Bool,
        hasFile: Bool,
        airDate: Date?,
        importedDate: Date?,
        quality: String?,
        tvdbSeriesID: String?,
        tvdbEpisodeID: String?,
        tmdbSeriesID: String?,
        artworkURL: URL?
    ) {
        self.id = id
        self.seriesID = seriesID
        self.seriesTitle = seriesTitle
        self.episodeTitle = episodeTitle
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.monitored = monitored
        self.hasFile = hasFile
        self.airDate = airDate
        self.importedDate = importedDate
        self.quality = quality
        self.tvdbSeriesID = tvdbSeriesID
        self.tvdbEpisodeID = tvdbEpisodeID
        self.tmdbSeriesID = tmdbSeriesID
        self.artworkURL = artworkURL
    }
}
