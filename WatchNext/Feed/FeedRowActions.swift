import SwiftUI
import WatchNextCore

/// Swipe and context-menu actions for a visible feed row.
struct HideActions: View {
    let item: MediaFeedItem
    let onHide: (HideScope) -> Void

    var body: some View {
        Button("Hide", systemImage: "eye.slash") {
            onHide(.item)
        }
        .tint(.orange)
        if item.seriesHideKey != nil {
            Button("Hide Series", systemImage: "tv.slash") {
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
        Button("Unhide", systemImage: "eye", action: onUnhide)
            .tint(.green)
    }
}
