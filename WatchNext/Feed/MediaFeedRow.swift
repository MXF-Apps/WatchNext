import SwiftUI
import WatchNextAppearance
import WatchNextCore

struct MediaFeedRow: View {
    let item: MediaFeedItem
    @Environment(\.appearance) private var appearance

    var body: some View {
        HStack(alignment: .top) {
            CachedArtworkView(cacheKey: item.artworkCacheKey)
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                if let subtitle {
                    subtitle
                        .font(.subheadline)
                        .lineLimit(2)
                }
                FeedItemDetail(item: item)
                if let progress = item.playbackProgress, progress > 0, progress < 1 {
                    ProgressView(value: progress)
                        .accessibilityLabel(String(localized: .mediaPlaybackProgressAccessibilityLabel))
                        .accessibilityValue(Text(progress, format: .percent))
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Episode code and title in gray, plus a bold "and N more" in the palette's
    /// emphasis color when the row stands in for a season.
    private var subtitle: Text? {
        let base = item.localizedSubtitle.map { Text($0).foregroundStyle(.secondary) }
        let more = item.collapsedEpisodesDescription.map { Text($0).bold().foregroundStyle(appearance.emphasis) }
        switch (base, more) {
        case let (base?, more?): return base + Text(verbatim: " · ").foregroundStyle(.secondary) + more
        case let (base?, nil): return base
        case let (nil, more?): return more
        case (nil, nil): return nil
        }
    }
}
