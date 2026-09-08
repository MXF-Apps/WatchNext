import SwiftUI
import WatchNextAppearance
import WatchNextCore

struct FeedItemDetail: View {
    @Environment(\.palette) private var palette
    let item: MediaFeedItem

    var body: some View {
        HStack {
            // Label's default icon gap reads loose next to footnote text; the
            // glyph and its text form one unit with a 4 pt gap.
            if item.availability == .ready {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(String(localized: .mediaAvailabilityReadyLabel))
                }
                .foregroundStyle(palette.ready)
                .accessibilityElement(children: .combine)
            } else if item.isAwaitingDownload, let releaseDate = item.releaseDate {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                    Text(item.kind == .movie
                        ? LocalizedStringResource.mediaReleaseMovieLabel(time: releaseDate.formatted(.relative(presentation: .named)))
                        : .mediaReleaseEpisodeLabel(time: releaseDate.formatted(.relative(presentation: .named))))
                }
                .fontWeight(.semibold)
                .foregroundStyle(palette.released)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: item.kind == .movie
                    ? .mediaReleaseMovieAccessibilityLabel(time: releaseDate.formatted(.relative(presentation: .named)))
                    : .mediaReleaseEpisodeAccessibilityLabel(time: releaseDate.formatted(.relative(presentation: .named)))))
            } else if let releaseDate = item.releaseDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text(releaseDate, format: .dateTime.weekday(.wide).month().day())
                }
                .accessibilityElement(children: .combine)
            }
            if let quality = item.qualityDescription {
                Text(quality)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}
