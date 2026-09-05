import WatchNextCore

/// Lines per row. Candidates are tried in order until one fits the family.
enum WidgetRowStyle: Hashable {
    /// Title, subtitle, status.
    case comfortable
    /// Title plus one secondary line.
    case compact
    /// Single line: title with a trailing hint.
    case dense
}

/// One layout attempt: how many items per section and how tightly to draw them.
struct WidgetLayoutCandidate: Hashable, Identifiable {
    let ready: Int
    let coming: Int
    let style: WidgetRowStyle

    var id: Self { self }

    /// Expands (ready, coming) pairs — ordered by how many items they show —
    /// into candidates for the density, clamped to what the feed has, with
    /// duplicates removed so the layout engine measures each shape once.
    static func make(
        pairs: [(ready: Int, coming: Int)],
        density: RowDensity,
        feed: WatchNextFeed
    ) -> [WidgetLayoutCandidate] {
        var seen = Set<WidgetLayoutCandidate>()
        var result: [WidgetLayoutCandidate] = []
        for pair in pairs {
            let ready = min(pair.ready, feed.ready.count)
            let coming = min(pair.coming, feed.comingSoon.count)
            guard ready + coming > 0 else { continue }
            for style in density.rowStyles {
                let candidate = WidgetLayoutCandidate(ready: ready, coming: coming, style: style)
                if seen.insert(candidate).inserted {
                    result.append(candidate)
                }
            }
        }
        return result
    }
}
