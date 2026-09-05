import Foundation
import Testing
import WatchNextCore

struct FixtureSnapshot: Decodable {
    let sonarrEpisodes: [SonarrEpisode]
    let radarrMovies: [RadarrMovie]
    let jellyfinItems: [JellyfinMediaItem]

    var sourceSnapshot: SourceSnapshot {
        SourceSnapshot(
            sonarrEpisodes: sonarrEpisodes,
            radarrMovies: radarrMovies,
            jellyfinItems: jellyfinItems
        )
    }

    static func load() throws -> FixtureSnapshot {
        let url = try #require(Bundle.module.url(forResource: "matching", withExtension: "json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(FixtureSnapshot.self, from: Data(contentsOf: url))
    }
}
