import SwiftUI
import WatchNextAppearance
import WatchNextCore

/// Ready and Coming Soon side by side, text-only, as many rows as fit.
struct MediumWidgetContent: View {
    @Environment(\.palette) private var palette
    let entry: WatchNextEntry

    private static let pairs: [(ready: Int, coming: Int)] = [(6, 6), (5, 5), (4, 4), (3, 3), (2, 2), (1, 1)]

    var body: some View {
        ViewThatFits(in: .vertical) {
            ForEach(WidgetLayoutCandidate.make(pairs: Self.pairs, density: entry.density, feed: entry.feed)) { candidate in
                columns(candidate)
            }
        }
    }

    private func columns(_ candidate: WidgetLayoutCandidate) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if candidate.ready > 0 {
                WidgetSectionView(
                    title: String(localized: .widgetSectionReadyTitle),
                    items: entry.feed.ready.prefix(candidate.ready),
                    totalCount: entry.feed.ready.count,
                    artwork: entry.artwork,
                    style: candidate.style,
                    showsArtwork: false,
                    titleFont: .footnote,
                    secondaryFont: .caption2,
                    accessories: WidgetSectionAccessories(feed: entry.feed),
                    hintFormat: .short,
                    sectionColor: palette.ready
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if candidate.coming > 0 {
                WidgetSectionView(
                    title: String(localized: .widgetSectionComingSoonTitle),
                    items: entry.feed.comingSoon.prefix(candidate.coming),
                    totalCount: entry.feed.comingSoon.count,
                    artwork: entry.artwork,
                    style: candidate.style,
                    showsArtwork: false,
                    titleFont: .footnote,
                    secondaryFont: .caption2,
                    accessories: candidate.ready == 0 ? WidgetSectionAccessories(feed: entry.feed) : nil,
                    hintFormat: .short,
                    sectionColor: palette.upcoming
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
