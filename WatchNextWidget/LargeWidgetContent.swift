import SwiftUI
import WatchNextCore

/// Stacked sections, optional artwork, row counts step down until it fits.
struct LargeWidgetContent: View {
    let entry: WatchNextEntry

    private static let pairs: [(ready: Int, coming: Int)] = [
        (12, 6), (12, 4), (10, 4), (8, 4), (8, 3), (7, 3), (6, 3), (6, 2), (5, 3), (5, 2),
        (4, 3), (4, 2), (3, 3), (3, 2), (2, 2), (2, 1), (1, 1), (1, 0), (0, 1)
    ]

    var body: some View {
        ViewThatFits(in: .vertical) {
            ForEach(WidgetLayoutCandidate.make(pairs: Self.pairs, density: entry.density, feed: entry.feed)) { candidate in
                if entry.showsSectionTitles {
                    WidgetStackedLayout(
                        entry: entry,
                        candidate: candidate,
                        readyTitle: String(localized: .widgetSectionReadyToWatchTitle),
                        titleFont: .subheadline,
                        secondaryFont: .caption,
                        showsArtwork: entry.showsArtwork && candidate.style == .comfortable
                    )
                } else {
                    WidgetPlainLayout(
                        entry: entry,
                        candidate: candidate,
                        titleFont: .subheadline,
                        secondaryFont: .caption,
                        showsArtwork: entry.showsArtwork && candidate.style == .comfortable,
                        hintFormat: .full
                    )
                }
            }
        }
    }
}
