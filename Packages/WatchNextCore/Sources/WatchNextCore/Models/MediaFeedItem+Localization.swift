import Foundation

public extension MediaFeedItem {
    /// Resolve presentation text at display time, not when writing the shared feed cache.
    var localizedSubtitle: String? {
        kind == .movie ? String(localized: "media.kind.movie.label", defaultValue: "Movie", bundle: .module) : subtitle
    }
}
