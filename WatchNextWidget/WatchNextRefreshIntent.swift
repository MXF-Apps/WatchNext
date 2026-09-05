import AppIntents
import WidgetKit
import WatchNextCore

struct WatchNextRefreshIntent: AppIntent {
    static let title: LocalizedStringResource = "Refresh WatchNext"
    static let description = IntentDescription("Refreshes the WatchNext feed from your configured media services.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        logger.info("Widget manual refresh requested.", category: "Widget")
        do {
            _ = try await WatchNextDependencies.live.feedService.refresh()
        } catch {
            logger.error("Widget manual refresh failed; cached data was preserved.", error: error, category: "Widget")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: WatchNextConstants.widgetKind)
        return .result()
    }
}
