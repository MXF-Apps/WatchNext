import SwiftUI
import WatchNextAppearance
import WatchNextCore

/// A titled group of rows. Overflow count, refresh button, and status live on
/// the title line so they never cost vertical space.
struct WidgetSectionView: View {
    let title: String
    let items: ArraySlice<MediaFeedItem>
    let totalCount: Int
    let artwork: [String: Data]
    let style: WidgetRowStyle
    let showsArtwork: Bool
    let titleFont: Font
    let secondaryFont: Font
    /// Only the first section on a widget carries the refresh control and stamps.
    var accessories: WidgetSectionAccessories? = nil
    var hintFormat: WidgetHintFormat = .full

    var body: some View {
        VStack(alignment: .leading, spacing: style == .dense ? 2 : 3) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                // Right after the title, so "+3" reads as part of the section
                // count rather than floating at the trailing edge.
                if totalCount > items.count {
                    Text(String(localized: .widgetOverflowLabel(count: totalCount - items.count)))
                        .accessibilityLabel(String(localized: .widgetOverflowAccessibilityLabel(count: totalCount - items.count)))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                if let accessories {
                    accessories
                }
            }
            ForEach(items) { item in
                WidgetItemRow(
                    item: item,
                    artwork: artwork,
                    style: style,
                    showsArtwork: showsArtwork,
                    titleFont: titleFont,
                    secondaryFont: secondaryFont,
                    hintFormat: hintFormat
                )
            }
        }
    }
}

/// Error hint and refresh button for a section title line.
struct WidgetSectionAccessories: View {
    @Environment(\.palette) private var palette
    let feed: WatchNextFeed

    var body: some View {
        if feed.lastRefreshError != nil {
            Image(systemName: "wifi.exclamationmark")
                .font(.caption2)
                .foregroundStyle(palette.alert)
                .accessibilityLabel(String(localized: .widgetRefreshErrorAccessibilityLabel))
        }
        Button(intent: WatchNextRefreshIntent()) {
            Image(systemName: "arrow.clockwise")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(feed.lastRefreshError == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(palette.alert))
                .accessibilityLabel(String(localized: .widgetRefreshButtonAccessibilityLabel))
        }
        .buttonStyle(.plain)
    }
}
