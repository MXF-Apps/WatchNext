import SwiftUI
import WatchNextCore

/// Layout without section titles: ready rows, then a divider, then upcoming
/// rows with their tinted time. The divider carries everything the titles
/// used to: "↑ +N more" in green on the left for the ready rows above it,
/// "+N more ↓" in the upcoming tint on the right for the rows below, and the
/// refresh button as a break in the middle of the line.
struct WidgetPlainLayout: View {
    let entry: WatchNextEntry
    let candidate: WidgetLayoutCandidate
    let titleFont: Font
    let secondaryFont: Font
    let showsArtwork: Bool
    let hintFormat: WidgetHintFormat

    var body: some View {
        let ready = entry.feed.ready.prefix(candidate.ready)
        let coming = entry.feed.comingSoon.prefix(candidate.coming)
        let readyOverflow = entry.feed.ready.count - ready.count
        let comingOverflow = entry.feed.comingSoon.count - coming.count
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(ready) { item in
                row(item)
            }
            if ready.isEmpty == false || coming.isEmpty == false {
                HStack(spacing: 6) {
                    if readyOverflow > 0 {
                        overflow(readyOverflow, arrow: "arrow.up", color: Color.green, arrowFirst: true)
                    }
                    line
                    Button(intent: WatchNextRefreshIntent()) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(String(localized: .widgetRefreshButtonAccessibilityLabel))
                    }
                    .buttonStyle(.plain)
                    line
                    if comingOverflow > 0 {
                        overflow(comingOverflow, arrow: "arrow.down", color: WidgetItemRow.timeColor, arrowFirst: false)
                    }
                }
                .padding(.vertical, 2)
            }
            ForEach(coming) { item in
                row(item)
            }
        }
    }

    private var line: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(height: 1)
    }

    private var rowSpacing: CGFloat {
        switch candidate.style {
        case .dense: 2
        case .compact: 3
        case .comfortable: 5
        }
    }

    private func row(_ item: MediaFeedItem) -> some View {
        WidgetItemRow(
            item: item,
            artwork: entry.artwork,
            style: candidate.style,
            showsArtwork: showsArtwork,
            titleFont: titleFont,
            secondaryFont: secondaryFont,
            hintFormat: hintFormat
        )
    }

    /// "↑ +2 more" or "+1 more ↓": the arrow says which side of the divider the count belongs to.
    private func overflow(_ count: Int, arrow: String, color: some ShapeStyle, arrowFirst: Bool) -> some View {
        HStack(spacing: 2) {
            if arrowFirst {
                Image(systemName: arrow)
            }
            Text(String(localized: .widgetOverflowLabel(count: count)))
            if arrowFirst == false {
                Image(systemName: arrow)
            }
        }
        .font(.caption2)
        .foregroundStyle(color)
        .lineLimit(1)
        .fixedSize()
        .accessibilityLabel(arrowFirst ? String(localized: .widgetOverflowReadyAccessibilityLabel(count: count)) : String(localized: .widgetOverflowUpcomingAccessibilityLabel(count: count)))
    }
}
