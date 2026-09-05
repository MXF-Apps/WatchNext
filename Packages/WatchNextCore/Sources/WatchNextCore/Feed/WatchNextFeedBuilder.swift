import Foundation

public struct WatchNextFeedBuilder: FeedBuilding {
    private let matcher: MediaMatcher
    private let calendar: Calendar

    public init(matcher: MediaMatcher = .init(), calendar: Calendar = .current) {
        self.matcher = matcher
        self.calendar = calendar
    }

    public func build(
        snapshot: SourceSnapshot,
        configuration: ServiceConfiguration,
        now: Date = .now
    ) -> WatchNextFeed {
        let recentStart = configuration.recentStart(now: now, calendar: calendar)
        let futureEnd = configuration.futureEnd(now: now, calendar: calendar)

        let readyEpisodes = snapshot.sonarrEpisodes.compactMap {
            readyEpisode($0, jellyfinItems: snapshot.jellyfinItems, recentStart: recentStart, now: now)
        }
        let readyMovies = snapshot.radarrMovies.compactMap {
            readyMovie($0, jellyfinItems: snapshot.jellyfinItems, recentStart: recentStart, now: now)
        }
        let ready = deduplicate(readyEpisodes + readyMovies)
            .sorted { ($0.importedDate ?? .distantPast) > ($1.importedDate ?? .distantPast) }
        let readyIDs = Set(ready.map(\.id))

        let comingEpisodes = snapshot.sonarrEpisodes.compactMap {
            comingEpisode(
                $0,
                jellyfinItems: snapshot.jellyfinItems,
                recentStart: recentStart,
                now: now,
                futureEnd: futureEnd
            )
        }
        let comingMovies = snapshot.radarrMovies.compactMap {
            comingMovie(
                $0,
                jellyfinItems: snapshot.jellyfinItems,
                recentStart: recentStart,
                now: now,
                futureEnd: futureEnd
            )
        }
        let comingSoon = deduplicate(comingEpisodes + comingMovies)
            .filter { readyIDs.contains($0.id) == false }
            .sorted { ($0.releaseDate ?? .distantFuture) < ($1.releaseDate ?? .distantFuture) }

        return WatchNextFeed(ready: ready, comingSoon: comingSoon)
    }

    private func readyEpisode(
        _ episode: SonarrEpisode,
        jellyfinItems: [JellyfinMediaItem],
        recentStart: Date,
        now: Date
    ) -> MediaFeedItem? {
        guard
            episode.hasFile,
            let importedDate = episode.importedDate,
            importedDate >= recentStart,
            importedDate <= now,
            let jellyfin = matcher.matchEpisode(episode, in: jellyfinItems),
            jellyfin.isPlayed == false
        else { return nil }

        return MediaFeedItem(
            id: "episode:\(episode.id)",
            kind: .episode,
            title: jellyfin.seriesName ?? episode.seriesTitle,
            subtitle: EpisodeSubtitle.make(
                season: episode.seasonNumber,
                episode: episode.episodeNumber,
                title: jellyfin.name.isEmpty ? episode.episodeTitle : jellyfin.name
            ),
            artworkURL: jellyfin.artworkURL ?? episode.artworkURL,
            artworkCacheKey: "jellyfin-\(jellyfin.id)",
            availability: .ready,
            releaseDate: episode.airDate,
            importedDate: importedDate,
            isWatched: false,
            playbackProgress: jellyfin.playbackProgress,
            qualityDescription: episode.quality,
            sourceIDs: .init(
                sonarrID: episode.id,
                sonarrSeriesID: episode.seriesID,
                jellyfinID: jellyfin.id,
                tvdbID: episode.tvdbEpisodeID,
                tmdbID: episode.tmdbSeriesID
            ),
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber
        )
    }

    private func readyMovie(
        _ movie: RadarrMovie,
        jellyfinItems: [JellyfinMediaItem],
        recentStart: Date,
        now: Date
    ) -> MediaFeedItem? {
        guard
            movie.hasFile,
            let importedDate = movie.importedDate,
            importedDate >= recentStart,
            importedDate <= now,
            let jellyfin = matcher.matchMovie(movie, in: jellyfinItems),
            jellyfin.isPlayed == false
        else { return nil }

        return MediaFeedItem(
            id: "movie:\(movie.id)",
            kind: .movie,
            title: jellyfin.name,
            subtitle: "Movie",
            artworkURL: jellyfin.artworkURL ?? movie.artworkURL,
            artworkCacheKey: "jellyfin-\(jellyfin.id)",
            availability: .ready,
            releaseDate: movie.releaseDate,
            importedDate: importedDate,
            isWatched: false,
            playbackProgress: jellyfin.playbackProgress,
            qualityDescription: movie.quality,
            sourceIDs: .init(
                radarrID: movie.id,
                jellyfinID: jellyfin.id,
                tmdbID: movie.tmdbID,
                imdbID: movie.imdbID
            )
        )
    }

    /// Upcoming when the date is ahead; awaiting download when it has passed
    /// within the recent window and nothing has been imported yet.
    private func upcomingAvailability(for date: Date, recentStart: Date, now: Date, futureEnd: Date) -> AvailabilityState? {
        if date > now {
            return date <= futureEnd ? .comingSoon : nil
        }
        return date >= recentStart ? .awaitingDownload : nil
    }

    private func comingEpisode(
        _ episode: SonarrEpisode,
        jellyfinItems: [JellyfinMediaItem],
        recentStart: Date,
        now: Date,
        futureEnd: Date
    ) -> MediaFeedItem? {
        guard
            episode.monitored,
            episode.hasFile == false,
            let airDate = episode.airDate,
            let availability = upcomingAvailability(for: airDate, recentStart: recentStart, now: now, futureEnd: futureEnd),
            matcher.matchEpisode(episode, in: jellyfinItems) == nil
        else { return nil }

        return MediaFeedItem(
            id: "episode:\(episode.id)",
            kind: .episode,
            title: episode.seriesTitle,
            subtitle: EpisodeSubtitle.make(
                season: episode.seasonNumber,
                episode: episode.episodeNumber,
                title: episode.episodeTitle
            ),
            artworkURL: episode.artworkURL,
            artworkCacheKey: "sonarr-series-\(episode.seriesID)",
            availability: availability,
            releaseDate: airDate,
            sourceIDs: .init(
                sonarrID: episode.id,
                sonarrSeriesID: episode.seriesID,
                tvdbID: episode.tvdbEpisodeID,
                tmdbID: episode.tmdbSeriesID
            ),
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber
        )
    }

    private func comingMovie(
        _ movie: RadarrMovie,
        jellyfinItems: [JellyfinMediaItem],
        recentStart: Date,
        now: Date,
        futureEnd: Date
    ) -> MediaFeedItem? {
        guard
            movie.monitored,
            movie.hasFile == false,
            let releaseDate = movie.releaseDate,
            let availability = upcomingAvailability(for: releaseDate, recentStart: recentStart, now: now, futureEnd: futureEnd),
            matcher.matchMovie(movie, in: jellyfinItems) == nil
        else { return nil }

        return MediaFeedItem(
            id: "movie:\(movie.id)",
            kind: .movie,
            title: movie.title,
            subtitle: "Movie",
            artworkURL: movie.artworkURL,
            artworkCacheKey: "radarr-movie-\(movie.id)",
            availability: availability,
            releaseDate: releaseDate,
            sourceIDs: .init(
                radarrID: movie.id,
                tmdbID: movie.tmdbID,
                imdbID: movie.imdbID
            )
        )
    }

    private func deduplicate(_ items: [MediaFeedItem]) -> [MediaFeedItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }
}
