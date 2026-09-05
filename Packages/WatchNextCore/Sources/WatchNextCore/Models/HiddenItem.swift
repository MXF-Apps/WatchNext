/// A user choice to keep media out of the feed.
///
/// Entries are keyed by stable upstream identifiers so they survive refreshes,
/// and are pruned once nothing in the feed matches them any more.
public enum HiddenItem: Codable, Hashable, Sendable {
    /// Hides one feed item (a movie or a single episode) by its feed ID.
    case item(id: String)
    /// Hides every episode of a Sonarr series, ready or upcoming.
    case series(sonarrSeriesID: Int)

    /// Whether this entry applies to the given item.
    public func matches(_ item: MediaFeedItem) -> Bool {
        switch self {
        case .item(let id):
            item.id == id
        case .series(let seriesID):
            item.sourceIDs.sonarrSeriesID == seriesID
        }
    }
}

public extension MediaFeedItem {
    /// The entry that hides exactly this item.
    var itemHideKey: HiddenItem { .item(id: id) }

    /// The entry that hides this item's whole series, when it belongs to one.
    var seriesHideKey: HiddenItem? {
        sourceIDs.sonarrSeriesID.map { .series(sonarrSeriesID: $0) }
    }

    func isHidden(by hidden: Set<HiddenItem>) -> Bool {
        hidden.contains { $0.matches(self) }
    }
}
