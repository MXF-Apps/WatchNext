/// Narrows the feed to one media kind.
public enum FeedKindFilter: String, CaseIterable, Codable, Hashable, Sendable {
    case all
    case movies
    case shows

    public func includes(_ kind: MediaKind) -> Bool {
        switch self {
        case .all: true
        case .movies: kind == .movie
        case .shows: kind == .episode
        }
    }

    public var displayName: String {
        switch self {
        case .all: "All"
        case .movies: "Movies"
        case .shows: "Shows"
        }
    }
}
