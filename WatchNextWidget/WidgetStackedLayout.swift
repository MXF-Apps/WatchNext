import SwiftUI
import WatchNextAppearance
import WatchNextCore

/// Ready above Coming Soon, used by the small and large families.
struct WidgetStackedLayout: View {
    @Environment(\.palette) private var palette
    let entry: WatchNextEntry
    let candidate: WidgetLayoutCandidate
    let readyTitle: String
    var comingTitle = String(localized: .widgetSectionComingSoonTitle)
    let titleFont: Font
    let secondaryFont: Font
    let showsArtwork: Bool
    var hintFormat: WidgetHintFormat = .full

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if candidate.ready > 0 {
                WidgetSectionView(
                    title: readyTitle,
                    items: entry.feed.ready.prefix(candidate.ready),
                    totalCount: entry.feed.ready.count,
                    artwork: entry.artwork,
                    style: candidate.style,
                    showsArtwork: showsArtwork,
                    titleFont: titleFont,
                    secondaryFont: secondaryFont,
                    accessories: WidgetSectionAccessories(feed: entry.feed),
                    hintFormat: hintFormat,
                    sectionColor: palette.ready
                )
            }
            if candidate.coming > 0 {
                WidgetSectionView(
                    title: comingTitle,
                    items: entry.feed.comingSoon.prefix(candidate.coming),
                    totalCount: entry.feed.comingSoon.count,
                    artwork: entry.artwork,
                    style: candidate.style,
                    showsArtwork: showsArtwork,
                    titleFont: titleFont,
                    secondaryFont: secondaryFont,
                    accessories: candidate.ready == 0 ? WidgetSectionAccessories(feed: entry.feed) : nil,
                    hintFormat: hintFormat,
                    sectionColor: palette.upcoming
                )
            }
        }
    }
}
