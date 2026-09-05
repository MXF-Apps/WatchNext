import SwiftUI
import WidgetKit
import WatchNextCore

struct WatchNextWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var systemMargins
    let entry: WatchNextEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.feed.ready.isEmpty && entry.feed.comingSoon.isEmpty {
                HStack {
                    Spacer(minLength: 0)
                    WidgetSectionAccessories(feed: entry.feed)
                }
                Spacer()
                Label(emptyMessage, systemImage: "play.rectangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                switch family {
                case .systemSmall:
                    SmallWidgetContent(entry: entry)
                case .systemMedium:
                    MediumWidgetContent(entry: entry)
                default:
                    LargeWidgetContent(entry: entry)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(margins)
        .containerBackground(.background, for: .widget)
    }

    /// The HIG's tighter 11 pt margin where width is scarce; the system's otherwise.
    private var margins: EdgeInsets {
        family == .systemLarge ? systemMargins : EdgeInsets(top: 11, leading: 11, bottom: 11, trailing: 11)
    }

    private var emptyMessage: String {
        switch entry.kindFilter {
        case .all: "Open WatchNext to configure or refresh."
        case .movies: "No movies right now."
        case .shows: "No shows right now."
        }
    }
}
