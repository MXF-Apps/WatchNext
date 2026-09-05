import Testing
@testable import WatchNextCore

@Suite("Cross-service matching")
struct MediaMatcherTests {
    @Test("Radarr movie matches Jellyfin by TMDb ID")
    func movieTMDbMatch() throws {
        let fixture = try FixtureSnapshot.load()
        let movie = try #require(fixture.radarrMovies.first)
        let match = MediaMatcher().matchMovie(movie, in: fixture.jellyfinItems)
        #expect(match?.id == "jf-movie-dune")
    }

    @Test("Radarr movie falls back to IMDb ID")
    func movieIMDbMatch() throws {
        let fixture = try FixtureSnapshot.load()
        let original = try #require(fixture.radarrMovies.first)
        let movie = RadarrMovie(
            id: original.id,
            title: original.title,
            year: original.year,
            monitored: original.monitored,
            hasFile: original.hasFile,
            releaseDate: original.releaseDate,
            importedDate: original.importedDate,
            quality: original.quality,
            tmdbID: "wrong",
            imdbID: original.imdbID,
            artworkURL: nil
        )
        #expect(MediaMatcher().matchMovie(movie, in: fixture.jellyfinItems)?.id == "jf-movie-dune")
    }

    @Test("Sonarr series matches Jellyfin by TVDB ID")
    func seriesProviderMatch() throws {
        let fixture = try FixtureSnapshot.load()
        let episode = try #require(fixture.sonarrEpisodes.first)
        #expect(MediaMatcher().matchEpisode(episode, in: fixture.jellyfinItems)?.id == "jf-episode-305")
    }

    @Test("Episode falls back to season and episode after series match")
    func episodeNumberFallback() throws {
        let fixture = try FixtureSnapshot.load()
        let original = try #require(fixture.sonarrEpisodes.first)
        let episode = SonarrEpisode(
            id: original.id,
            seriesID: original.seriesID,
            seriesTitle: original.seriesTitle,
            episodeTitle: original.episodeTitle,
            seasonNumber: original.seasonNumber,
            episodeNumber: original.episodeNumber,
            monitored: original.monitored,
            hasFile: original.hasFile,
            airDate: original.airDate,
            importedDate: original.importedDate,
            quality: original.quality,
            tvdbSeriesID: original.tvdbSeriesID,
            tvdbEpisodeID: "wrong",
            tmdbSeriesID: original.tmdbSeriesID,
            artworkURL: nil
        )
        #expect(MediaMatcher().matchEpisode(episode, in: fixture.jellyfinItems)?.id == "jf-episode-305")
    }
}
