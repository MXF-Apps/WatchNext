import SwiftUI
import WatchNextAppearance
import WatchNextCore

struct FeedItemDetail: View {
    @Environment(\.palette) private var palette
    let item: MediaFeedItem

    var body: some View {
        HStack {
            if item.availability == .ready {
                Label(String(localized: .mediaAvailabilityReadyLabel), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(palette.ready)
            } else if item.isAwaitingDownload, let releaseDate = item.releaseDate {
                Label {
                    Text(item.kind == .movie
                        ? LocalizedStringResource.mediaReleaseMovieLabel(time: releaseDate.formatted(.relative(presentation: .named)))
                        : .mediaReleaseEpisodeLabel(time: releaseDate.formatted(.relative(presentation: .named))))
                } icon: {
                    Image(systemName: "magnifyingglass")
                }
                .foregroundStyle(palette.upcoming)
                .accessibilityLabel(String(localized: item.kind == .movie
                    ? .mediaReleaseMovieAccessibilityLabel(time: releaseDate.formatted(.relative(presentation: .named)))
                    : .mediaReleaseEpisodeAccessibilityLabel(time: releaseDate.formatted(.relative(presentation: .named)))))
            } else if let releaseDate = item.releaseDate {
                Label {
                    Text(releaseDate, format: .dateTime.weekday(.wide).month().day())
                } icon: {
                    Image(systemName: "calendar")
                }
            }
            if let quality = item.qualityDescription {
                Text(quality)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}
