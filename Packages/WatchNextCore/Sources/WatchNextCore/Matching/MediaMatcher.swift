import Foundation

public struct MediaMatcher: Sendable {
    public init() {}

    public func matchMovie(_ movie: RadarrMovie, in items: [JellyfinMediaItem]) -> JellyfinMediaItem? {
        let movies = items.filter { $0.kind == .movie }
        if let tmdbID = movie.tmdbID,
           let match = movies.first(where: { providerID("Tmdb", in: $0.providerIDs) == tmdbID }) {
            return match
        }
        if let imdbID = movie.imdbID,
           let match = movies.first(where: { providerID("Imdb", in: $0.providerIDs) == imdbID }) {
            return match
        }
        let fallback = movies.first {
            normalized($0.name) == normalized(movie.title)
                && compatibleYears($0.productionYear, movie.year)
        }
        logFailureIfNeeded(fallback == nil, source: "Radarr", id: movie.id)
        return fallback
    }

    public func matchEpisode(_ episode: SonarrEpisode, in items: [JellyfinMediaItem]) -> JellyfinMediaItem? {
        let episodes = items.filter { $0.kind == .episode }
        let matchingSeries = episodes.filter { item in
            if let tvdbID = episode.tvdbSeriesID,
               providerID("Tvdb", in: item.seriesProviderIDs) == tvdbID {
                return true
            }
            if let tmdbID = episode.tmdbSeriesID,
               providerID("Tmdb", in: item.seriesProviderIDs) == tmdbID {
                return true
            }
            return normalized(item.seriesName ?? "") == normalized(episode.seriesTitle)
        }

        if let tvdbEpisodeID = episode.tvdbEpisodeID,
           let match = matchingSeries.first(where: {
               providerID("Tvdb", in: $0.providerIDs) == tvdbEpisodeID
           }) {
            return match
        }
        let fallback = matchingSeries.first {
            $0.seasonNumber == episode.seasonNumber && $0.episodeNumber == episode.episodeNumber
        }
        logFailureIfNeeded(fallback == nil, source: "Sonarr", id: episode.id)
        return fallback
    }

    private func providerID(_ name: String, in identifiers: [String: String]) -> String? {
        identifiers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) ? Character(String($0)) : " " }
            .reduce(into: "") { $0.append($1) }
            .split(whereSeparator: \Character.isWhitespace)
            .joined(separator: " ")
    }

    private func compatibleYears(_ first: Int?, _ second: Int?) -> Bool {
        guard let first, let second else { return true }
        return first == second
    }

    private func logFailureIfNeeded(_ failed: Bool, source: String, id: Int) {
        #if DEBUG
        if failed {
            logger.debug(
                "No deterministic Jellyfin match for \(source) item ID \(id).",
                category: "Matching"
            )
        }
        #endif
    }
}
