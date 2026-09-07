import SwiftUI
import WatchNextCore

struct FeedScreen: View {
    @EnvironmentObject private var model: WatchNextAppModel

    var body: some View {
        NavigationStack {
            FeedList()
            .navigationTitle(String(localized: .appName))
            .toolbar {
                if model.isSelectingItems {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: .feedActionsDoneButton)) { model.isSelectingItems = false }
                            .fontWeight(.semibold)
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu(String(localized: .feedActionsOptionsButton), systemImage: "ellipsis.circle") {
                            Button(String(localized: .feedActionsSelectButton), systemImage: "checkmark.circle") {
                                model.isSelectingItems = true
                            }
                            Toggle(String(localized: .feedActionsShowHiddenToggle), systemImage: "eye", isOn: $model.showsHiddenItems)
                            if model.hiddenFeedItems.isEmpty == false {
                                Text(String(localized: .feedHiddenCount(count: model.hiddenFeedItems.count)))
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: .feedActionsRefreshButton), systemImage: "arrow.clockwise", action: refresh)
                            .disabled(model.isRefreshing)
                    }
                }
            }
            .overlay {
                if model.isRefreshing {
                    ProgressView(String(localized: .feedRefreshProgress))
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(.rect(cornerRadius: 12))
                }
            }
        }
    }

    private func refresh() {
        Task { await model.refresh() }
    }
}
