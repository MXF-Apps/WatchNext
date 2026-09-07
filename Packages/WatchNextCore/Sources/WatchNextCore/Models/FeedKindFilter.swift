import Foundation

/// Narrows the feed to one media kind.
public enum FeedKindFilter: String, CaseIterable, Codable, Hashable, Sendable {
    case all
    case movies
    case shows

    /// Matches a stored display name or raw value regardless of case.
    public init?(storedValue: String?) {
        guard let storedValue else { return nil }
        guard let match = Self.allCases.first(where: {
            $0.rawValue.caseInsensitiveCompare(storedValue) == .orderedSame
        }) else { return nil }
        self = match
    }

    public func includes(_ kind: MediaKind) -> Bool {
        switch self {
        case .all: true
        case .movies: kind == .movie
        case .shows: kind == .episode
        }
    }

    public var displayName: String {
        switch self {
        case .all: String(localized: "media.filter.all.title", defaultValue: "All", bundle: .module)
        case .movies: String(localized: "media.filter.movies.title", defaultValue: "Movies", bundle: .module)
        case .shows: String(localized: "media.filter.shows.title", defaultValue: "Shows", bundle: .module)
        }
    }
}
