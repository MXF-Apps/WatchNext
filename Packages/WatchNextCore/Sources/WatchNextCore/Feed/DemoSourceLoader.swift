import Foundation
import WatchNextLogging

/// A fictional Sonarr, Radarr and Jellyfin snapshot for demo mode.
///
/// Titles, identifiers and posters are invented, so nothing here belongs to a
/// real production. Dates are relative to `now`, so the feed always looks
/// fresh: a freshly imported season, a movie half watched, an episode that
/// aired hours ago and is still missing, and releases a few days out. Posters
/// are copied from the package's resources straight into the shared artwork
/// cache under the keys the feed builder will ask for.
public struct DemoSourceLoader: SourceLoading {
    public init() {}

    public func load(configuration: ServiceConfiguration) async throws -> SourceSnapshot {
        let now = Date.now
        let snapshot = Self.snapshot(now: now)
        Self.installPosters()
        logger.info(
            "Demo catalog loaded: \(snapshot.sonarrEpisodes.count) episodes, \(snapshot.radarrMovies.count) movies, \(snapshot.jellyfinItems.count) library items.",
            category: "Demo"
        )
        return snapshot
    }

    public func credentials() async throws -> [CredentialKey: String] { [:] }

    // MARK: Catalog

    struct Show {
        let id: Int
        let slug: String
        let title: String
        let tvdb: Int
        let episodes: [Episode]
    }

    struct Episode {
        let season: Int
        let number: Int
        let title: String
        let aired: TimeInterval
        let imported: TimeInterval?
        let watched: Bool
        let progress: Double?
    }

    struct Movie {
        let id: Int
        let slug: String
        let title: String
        let year: Int
        let tmdb: Int
        let imported: TimeInterval?
        let release: TimeInterval
        let quality: String?
        let progress: Double?
    }

    static let hour: TimeInterval = 3600
    static let day: TimeInterval = 86_400

    static let shows: [Show] = [
        Show(id: 1, slug: "harbor-lights", title: "Harbor Lights", tvdb: 910_001, episodes:
            ["North Pier", "The Keeper's Daughter", "Fog Signals", "Undertow", "Low Water", "Last Light"]
                .enumerated().map { index, title in
                    Episode(season: 2, number: index + 1, title: title,
                            aired: -Double(9 - (index + 1)) * day, imported: -(day + 3 * hour), watched: false, progress: nil)
                }),
        Show(id: 2, slug: "the-cartographers", title: "The Cartographers", tvdb: 910_002, episodes: [
            Episode(season: 1, number: 1, title: "Blank Spaces", aired: -30 * day, imported: -28 * day, watched: true, progress: nil),
            Episode(season: 1, number: 2, title: "Contour Lines", aired: -23 * day, imported: -21 * day, watched: true, progress: nil),
            Episode(season: 1, number: 3, title: "Dead Reckoning", aired: -16 * day, imported: -14 * day, watched: true, progress: nil),
            Episode(season: 1, number: 4, title: "The Salt Road", aired: -(2 * day + 5 * hour), imported: -2 * day, watched: false, progress: 0.35)
        ]),
        Show(id: 3, slug: "ninefold-station", title: "Ninefold Station", tvdb: 910_003, episodes: [
            Episode(season: 3, number: 9, title: "Airlock Nine", aired: -5 * day, imported: -5 * day, watched: true, progress: nil),
            Episode(season: 3, number: 10, title: "Pressure Drop", aired: 2 * day + 4 * hour, imported: nil, watched: false, progress: nil),
            Episode(season: 3, number: 11, title: "Quiet Orbit", aired: 9 * day + 4 * hour, imported: nil, watched: false, progress: nil)
        ]),
        Show(id: 4, slug: "saltmarsh", title: "Saltmarsh", tvdb: 910_004, episodes: [
            Episode(season: 1, number: 1, title: "Spring Tide", aired: -3 * hour, imported: nil, watched: false, progress: nil)
        ])
    ]

    static let movies: [Movie] = [
        Movie(id: 101, slug: "paper-meridian", title: "Paper Meridian", year: 2026, tmdb: 820_001, imported: -(day + 8 * hour), release: -40 * day, quality: "Bluray-2160p", progress: nil),
        Movie(id: 102, slug: "the-long-static", title: "The Long Static", year: 2025, tmdb: 820_002, imported: -3 * day, release: -90 * day, quality: "WEBDL-1080p", progress: 0.4),
        Movie(id: 103, slug: "glasshouse-summer", title: "Glasshouse Summer", year: 2026, tmdb: 820_003, imported: -6 * day, release: -20 * day, quality: "Bluray-1080p", progress: nil),
        Movie(id: 104, slug: "vantablack-sonata", title: "Vantablack Sonata", year: 2026, tmdb: 820_004, imported: nil, release: 4 * day, quality: nil, progress: nil),
        Movie(id: 105, slug: "orbital-kitchen", title: "Orbital Kitchen", year: 2025, tmdb: 820_005, imported: -10 * day, release: -120 * day, quality: "WEBDL-2160p", progress: nil),
        Movie(id: 106, slug: "copper-and-tide", title: "Copper and Tide", year: 2026, tmdb: 820_006, imported: nil, release: 12 * day, quality: nil, progress: nil)
    ]

    static let episodeQuality = "WEBDL-1080p"

    static func episodeTVDB(_ show: Show, _ episode: Episode) -> String {
        String(700_000 + show.id * 1000 + episode.season * 100 + episode.number)
    }

    static func jellyfinEpisodeID(_ show: Show, _ episode: Episode) -> String {
        "demo-ep-\(show.id)-\(episode.season)-\(episode.number)"
    }

    static func jellyfinMovieID(_ movie: Movie) -> String { "demo-movie-\(movie.id)" }

    static func snapshot(now: Date) -> SourceSnapshot {
        var sonarrEpisodes: [SonarrEpisode] = []
        var radarrMovies: [RadarrMovie] = []
        var libraryItems: [JellyfinMediaItem] = []

        for show in Self.shows {
            for episode in show.episodes {
                let imported = episode.imported.map { now.addingTimeInterval($0) }
                sonarrEpisodes.append(SonarrEpisode(
                    id: show.id * 1000 + episode.season * 100 + episode.number,
                    seriesID: show.id,
                    seriesTitle: show.title,
                    episodeTitle: episode.title,
                    seasonNumber: episode.season,
                    episodeNumber: episode.number,
                    monitored: true,
                    hasFile: imported != nil,
                    airDate: now.addingTimeInterval(episode.aired),
                    importedDate: imported,
                    quality: imported == nil ? nil : episodeQuality,
                    tvdbSeriesID: String(show.tvdb),
                    tvdbEpisodeID: episodeTVDB(show, episode),
                    tmdbSeriesID: nil,
                    artworkURL: nil
                ))
                if imported != nil {
                    libraryItems.append(JellyfinMediaItem(
                        id: jellyfinEpisodeID(show, episode),
                        kind: .episode,
                        name: episode.title,
                        seriesName: show.title,
                        productionYear: nil,
                        seasonNumber: episode.season,
                        episodeNumber: episode.number,
                        isPlayed: episode.watched,
                        playbackProgress: episode.progress,
                        providerIDs: ["Tvdb": episodeTVDB(show, episode)],
                        seriesProviderIDs: ["Tvdb": String(show.tvdb)],
                        artworkURL: nil
                    ))
                }
            }
        }

        for movie in Self.movies {
            let imported = movie.imported.map { now.addingTimeInterval($0) }
            radarrMovies.append(RadarrMovie(
                id: movie.id,
                title: movie.title,
                year: movie.year,
                monitored: true,
                hasFile: imported != nil,
                releaseDate: now.addingTimeInterval(movie.release),
                importedDate: imported,
                quality: movie.quality,
                tmdbID: String(movie.tmdb),
                imdbID: "tt\(9_000_000 + movie.id)",
                artworkURL: nil
            ))
            if imported != nil {
                libraryItems.append(JellyfinMediaItem(
                    id: jellyfinMovieID(movie),
                    kind: .movie,
                    name: movie.title,
                    seriesName: nil,
                    productionYear: movie.year,
                    seasonNumber: nil,
                    episodeNumber: nil,
                    isPlayed: false,
                    playbackProgress: movie.progress,
                    providerIDs: ["Tmdb": String(movie.tmdb), "Imdb": "tt\(9_000_000 + movie.id)"],
                    seriesProviderIDs: [:],
                    artworkURL: nil
                ))
            }
        }

        return SourceSnapshot(sonarrEpisodes: sonarrEpisodes, radarrMovies: radarrMovies, jellyfinItems: libraryItems)
    }

    // MARK: Posters

    /// Cache keys the feed builder derives for each demo item, with the poster each should show.
    static var posterAssignments: [(cacheKey: String, slug: String)] {
        var result: [(String, String)] = []
        for show in shows {
            result.append(("sonarr-series-\(show.id)", show.slug))
            for episode in show.episodes where episode.imported != nil {
                result.append(("jellyfin-\(jellyfinEpisodeID(show, episode))", show.slug))
            }
        }
        for movie in movies {
            result.append(("radarr-movie-\(movie.id)", movie.slug))
            if movie.imported != nil {
                result.append(("jellyfin-\(jellyfinMovieID(movie))", movie.slug))
            }
        }
        return result
    }

    static func posterURL(for slug: String) -> URL? {
        Bundle.module.url(forResource: slug, withExtension: "png")
            ?? Bundle.module.url(forResource: slug, withExtension: "png", subdirectory: "DemoPosters")
    }

    /// Copies posters into the shared artwork cache so app and widget rows show them.
    static func installPosters() {
        for (cacheKey, slug) in posterAssignments {
            guard
                let destination = ArtworkLocation.fileURL(for: cacheKey),
                FileManager.default.fileExists(atPath: destination.path()) == false,
                let source = posterURL(for: slug)
            else { continue }
            do {
                try FileManager.default.createDirectory(
                    at: destination.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                logger.warning("Could not install demo poster \(slug).", error: error, category: "Demo")
            }
        }
    }
}
