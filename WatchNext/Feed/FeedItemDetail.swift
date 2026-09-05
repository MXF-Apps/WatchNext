import SwiftUI
import WatchNextCore

struct FeedItemDetail: View {
    let item: MediaFeedItem

    var body: some View {
        HStack {
            if item.availability == .ready {
                Label("Ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if item.isAwaitingDownload, let releaseDate = item.releaseDate {
                Label {
                    Text("\(item.kind == .movie ? "Released" : "Aired") \(releaseDate, format: .relative(presentation: .named))")
                } icon: {
                    Image(systemName: "magnifyingglass")
                }
                .foregroundStyle(.orange)
                .accessibilityLabel("\(item.kind == .movie ? "Released" : "Aired") \(releaseDate.formatted(.relative(presentation: .named))), not downloaded yet")
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
