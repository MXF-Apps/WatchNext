import SwiftUI
import WatchNextAppearance
import WatchNextCore

/// Swipe and context-menu actions for a visible feed row.
struct HideActions: View {
    @Environment(\.palette) private var palette
    let item: MediaFeedItem
    let onHide: (HideScope) -> Void

    var body: some View {
        Button(String(localized: .feedActionsHideButton), systemImage: "eye.slash") {
            onHide(.item)
        }
        .tint(palette.caution)
        if item.seriesHideKey != nil {
            Button(String(localized: .feedActionsHideSeriesButton), systemImage: "tv.slash") {
                onHide(.series)
            }
            .tint(palette.alert)
        }
    }
}

/// Swipe and context-menu action for a row in the Hidden section.
struct UnhideAction: View {
    @Environment(\.palette) private var palette
    let onUnhide: () -> Void

    var body: some View {
        Button(String(localized: .feedActionsUnhideButton), systemImage: "eye", action: onUnhide)
            .tint(palette.ready)
    }
}
