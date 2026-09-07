import SwiftUI
import WatchNextCore

/// Swipe and context-menu actions for a visible feed row.
struct HideActions: View {
    let item: MediaFeedItem
    let onHide: (HideScope) -> Void

    var body: some View {
        Button(String(localized: .feedActionsHideButton), systemImage: "eye.slash") {
            onHide(.item)
        }
        .tint(.orange)
        if item.seriesHideKey != nil {
            Button(String(localized: .feedActionsHideSeriesButton), systemImage: "tv.slash") {
                onHide(.series)
            }
            .tint(.red)
        }
    }
}

/// Swipe and context-menu action for a row in the Hidden section.
struct UnhideAction: View {
    let onUnhide: () -> Void

    var body: some View {
        Button(String(localized: .feedActionsUnhideButton), systemImage: "eye", action: onUnhide)
            .tint(.green)
    }
}
