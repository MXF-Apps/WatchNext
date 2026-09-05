import SwiftUI
import WidgetKit
import WatchNextCore

@main
struct WatchNextWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: WatchNextConstants.widgetKind,
            intent: WatchNextConfigurationIntent.self,
            provider: WatchNextTimelineProvider()
        ) { entry in
            WatchNextWidgetView(entry: entry)
        }
        // Margins are ours: 11 pt (the HIG's tighter grouping value) in small and
        // medium, the system's in large. See WatchNextWidgetView.
        .contentMarginsDisabled()
        .configurationDisplayName("WatchNext")
        .description("See what is ready to watch and what is coming next from your media library.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
