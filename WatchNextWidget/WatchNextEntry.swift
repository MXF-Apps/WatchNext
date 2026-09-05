import WidgetKit
import WatchNextCore

struct WatchNextEntry: TimelineEntry {
    let date: Date
    /// Already narrowed by the hidden list and the kind filter.
    let feed: WatchNextFeed
    let artwork: [String: Data]
    var density: RowDensity = .smart
    var kindFilter: FeedKindFilter = .all
    var showsArtwork = true
    var showsSectionTitles = true
}
