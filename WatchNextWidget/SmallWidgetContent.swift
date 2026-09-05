import SwiftUI
import WatchNextCore

/// Text-only rows, Ready first, Coming Soon when there is room.
struct SmallWidgetContent: View {
    let entry: WatchNextEntry

    private static let titledPairs: [(ready: Int, coming: Int)] = [
        (5, 2), (4, 2), (4, 1), (3, 2), (3, 1), (4, 0), (2, 2), (2, 1), (3, 0), (1, 1), (2, 0), (1, 0), (0, 1)
    ]

    /// Without section titles two more rows fit.
    private static let plainPairs: [(ready: Int, coming: Int)] = [
        (6, 3), (6, 2), (5, 2), (5, 1), (4, 2), (4, 1), (6, 0), (3, 2), (3, 1), (5, 0),
        (2, 2), (2, 1), (4, 0), (1, 1), (3, 0), (2, 0), (1, 0), (0, 2), (0, 1)
    ]

    var body: some View {
        if entry.showsSectionTitles {
            ViewThatFits(in: .vertical) {
                ForEach(WidgetLayoutCandidate.make(pairs: Self.titledPairs, density: entry.density, feed: entry.feed)) { candidate in
                    WidgetStackedLayout(
                        entry: entry,
                        candidate: candidate,
                        readyTitle: "Ready",
                        comingTitle: "Upcoming",
                        titleFont: .footnote,
                        secondaryFont: .caption2,
                        showsArtwork: false,
                        hintFormat: .short
                    )
                }
            }
        } else {
            ViewThatFits(in: .vertical) {
                ForEach(WidgetLayoutCandidate.make(pairs: Self.plainPairs, density: entry.density, feed: entry.feed)) { candidate in
                    WidgetPlainLayout(
                        entry: entry,
                        candidate: candidate,
                        titleFont: .footnote,
                        secondaryFont: .caption2,
                        showsArtwork: false,
                        hintFormat: .short
                    )
                }
            }
        }
    }
}

