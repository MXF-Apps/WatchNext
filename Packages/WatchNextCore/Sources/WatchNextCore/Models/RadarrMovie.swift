import Foundation

public struct RadarrMovie: Codable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let year: Int?
    public let monitored: Bool
    public let hasFile: Bool
    public let releaseDate: Date?
    public let importedDate: Date?
    public let quality: String?
    public let tmdbID: String?
    public let imdbID: String?
    public let artworkURL: URL?

    public init(
        id: Int,
        title: String,
        year: Int?,
        monitored: Bool,
        hasFile: Bool,
        releaseDate: Date?,
        importedDate: Date?,
        quality: String?,
        tmdbID: String?,
        imdbID: String?,
        artworkURL: URL?
    ) {
        self.id = id
        self.title = title
        self.year = year
        self.monitored = monitored
        self.hasFile = hasFile
        self.releaseDate = releaseDate
        self.importedDate = importedDate
        self.quality = quality
        self.tmdbID = tmdbID
        self.imdbID = imdbID
        self.artworkURL = artworkURL
    }
}
