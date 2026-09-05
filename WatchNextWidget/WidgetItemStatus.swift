import SwiftUI
import WatchNextCore

/// Ready badge or relative release time, for comfortable rows.
struct WidgetItemStatus: View {
    let item: MediaFeedItem
    var font: Font = .caption
    var hintFormat: WidgetHintFormat = .full

    var body: some View {
        if item.availability == .ready {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                joined(item.qualityDescription.map { "\($0) • Ready" } ?? "Ready")
            }
            .font(font)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        } else if item.isAwaitingDownload, let text = item.relativeReleaseText(hintFormat) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                joined(hintFormat == .full ? "\(item.kind == .movie ? "Released" : "Aired") \(text)" : text)
            }
            .font(font)
            .foregroundStyle(WidgetItemRow.timeColor)
            .lineLimit(1)
            .accessibilityLabel("\(item.kind == .movie ? "Released" : "Aired") \(text), not downloaded yet")
        } else if let text = item.relativeReleaseText(hintFormat) {
            joined(text)
                .font(font)
                .foregroundStyle(WidgetItemRow.timeColor)
                .lineLimit(1)
        }
    }

    /// Appends a bold, tinted "and N more" when the row stands in for a whole season.
    private func joined(_ text: String) -> Text {
        guard let more = item.collapsedEpisodesDescription else { return Text(text) }
        return Text(text) + Text(" · ") + Text(more).bold().foregroundStyle(.tint)
    }
}

extension MediaFeedItem {
    /// Full: "in 6 days", "in 22 hours", "2 hours ago" — never weeks or months.
    /// Short: "6d", "22h", "30m", or "now" within half a minute either way; past
    /// dates read the same as future ones and rely on the row's magnifier.
    func relativeReleaseText(_ format: WidgetHintFormat, now: Date = .now) -> String? {
        guard let releaseDate else { return nil }
        switch format {
        case .full:
            return releaseDate.formatted(
                Date.RelativeFormatStyle(
                    allowedFields: [.day, .hour, .minute],
                    presentation: .numeric,
                    unitsStyle: .wide
                )
            )
        case .short:
            let seconds = abs(releaseDate.timeIntervalSince(now))
            guard seconds >= 30 else { return "now" }
            let minutes = (seconds / 60).rounded()
            if minutes < 60 { return "\(Int(minutes))m" }
            let hours = (seconds / 3600).rounded()
            if hours < 24 { return "\(Int(hours))h" }
            return "\(Int((seconds / 86400).rounded()))d"
        }
    }

    /// Full: "S04E20". Short: "E20". Nil for movies.
    func episodeCode(_ format: WidgetHintFormat) -> String? {
        guard kind == .episode else { return nil }
        switch format {
        case .full:
            return shortSubtitle
        case .short:
            if let episodeNumber { return "E\(episodeNumber)" }
            return shortSubtitle?.components(separatedBy: "E").last.map { "E\($0)" }
        }
    }

    /// The episode code without the episode title ("S04E20"), or nil for movies.
    var shortSubtitle: String? {
        guard kind == .episode, let subtitle else { return nil }
        return subtitle.components(separatedBy: " — ").first
    }
}
