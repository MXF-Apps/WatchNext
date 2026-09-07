import SwiftUI
import WidgetKit
import WatchNextAppearance
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
        .containerBackground(for: .widget) {
            WidgetBackground()
        }
    }

    /// The HIG's tighter 11 pt margin where width is scarce; the system's otherwise.
    private var margins: EdgeInsets {
        family == .systemLarge ? systemMargins : EdgeInsets(top: 11, leading: 11, bottom: 11, trailing: 11)
    }

    private var emptyMessage: String {
        switch entry.kindFilter {
        case .all: String(localized: .widgetEmptyAllMessage)
        case .movies: String(localized: .widgetEmptyMoviesMessage)
        case .shows: String(localized: .widgetEmptyShowsMessage)
        }
    }
}


/// The widget background follows Settings › Appearance through the App Group.
/// `.background` is the system widget surface; the textured variant builds on
/// the matching elevated color so text contrast is unchanged.
private struct WidgetBackground: View {
    private let settings = AppearanceSettings.load(
        from: UserDefaults(suiteName: WatchNextConstants.appGroupIdentifier) ?? .standard
    )

    var body: some View {
        if settings.texture == .off {
            Rectangle().fill(.background)
        } else {
            AppBackground(settings: settings, base: Color(.secondarySystemGroupedBackground))
        }
    }
}
