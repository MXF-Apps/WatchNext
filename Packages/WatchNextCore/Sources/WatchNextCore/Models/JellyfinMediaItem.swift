import Foundation

public struct JellyfinMediaItem: Codable, Hashable, Sendable {
    public let id: String
    public let kind: MediaKind
    public let name: String
    public let seriesName: String?
    public let productionYear: Int?
    public let seasonNumber: Int?
    public let episodeNumber: Int?
    public let isPlayed: Bool
    public let playbackProgress: Double?
    public let providerIDs: [String: String]
    public let seriesProviderIDs: [String: String]
    public let artworkURL: URL?

    public init(
        id: String,
        kind: MediaKind,
        name: String,
        seriesName: String? = nil,
        productionYear: Int? = nil,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        isPlayed: Bool,
        playbackProgress: Double? = nil,
        providerIDs: [String: String] = [:],
        seriesProviderIDs: [String: String] = [:],
        artworkURL: URL? = nil
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.seriesName = seriesName
        self.productionYear = productionYear
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.isPlayed = isPlayed
        self.playbackProgress = playbackProgress
        self.providerIDs = providerIDs
        self.seriesProviderIDs = seriesProviderIDs
        self.artworkURL = artworkURL
    }
}
