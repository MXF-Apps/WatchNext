import SwiftUI
import WatchNextAppearance
import WatchNextCore

/// Ready badge or relative release time, for comfortable rows.
struct WidgetItemStatus: View {
    @Environment(\.palette) private var palette
    let item: MediaFeedItem
    var font: Font = .caption
    var hintFormat: WidgetHintFormat = .full

    var body: some View {
        if item.availability == .ready {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                joined(item.qualityDescription.map { String(localized: .mediaAvailabilityQualityLabel(quality: $0)) } ?? String(localized: .mediaAvailabilityReadyLabel))
            }
            .font(font)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        } else if item.isAwaitingDownload, let text = item.relativeReleaseText(hintFormat) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                joined(hintFormat == .full ? String(localized: item.kind == .movie ? .mediaReleaseMovieLabel(time: text) : .mediaReleaseEpisodeLabel(time: text)) : text)
            }
            .font(font)
            .fontWeight(.semibold)
            .foregroundStyle(palette.released)
            .lineLimit(1)
            .accessibilityLabel(String(localized: item.kind == .movie ? .mediaReleaseMovieAccessibilityLabel(time: text) : .mediaReleaseEpisodeAccessibilityLabel(time: text)))
        } else if let text = item.relativeReleaseText(hintFormat) {
            joined(text)
                .font(font)
                .foregroundStyle(palette.upcoming)
                .lineLimit(1)
        }
    }

    /// Appends a bold, tinted "and N more" when the row stands in for a whole season.
    private func joined(_ text: String) -> Text {
        guard let more = item.collapsedEpisodesDescription else { return Text(text) }
        return Text(text) + Text(verbatim: " · ") + Text(more).bold().foregroundStyle(palette.emphasis)
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
            guard seconds >= 30 else { return String(localized: .mediaReleaseNowLabel) }
            let minutes = (seconds / 60).rounded()
            if minutes < 60 { return Duration.seconds(minutes * 60).formatted(.units(allowed: [.minutes], width: .narrow)) }
            let hours = (seconds / 3600).rounded()
            if hours < 24 { return Duration.seconds(hours * 3600).formatted(.units(allowed: [.hours], width: .narrow)) }
            return Duration.seconds((seconds / 86400).rounded() * 86400).formatted(.units(allowed: [.days], width: .narrow))
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
