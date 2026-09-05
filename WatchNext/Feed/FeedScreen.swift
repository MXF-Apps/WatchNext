import SwiftUI
import WatchNextCore

struct FeedScreen: View {
    @EnvironmentObject private var model: WatchNextAppModel

    var body: some View {
        NavigationStack {
            FeedList()
            .navigationTitle("WatchNext")
            .toolbar {
                if model.isSelectingItems {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { model.isSelectingItems = false }
                            .fontWeight(.semibold)
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu("Options", systemImage: "ellipsis.circle") {
                            Button("Select Items", systemImage: "checkmark.circle") {
                                model.isSelectingItems = true
                            }
                            Toggle("Show Hidden", systemImage: "eye", isOn: $model.showsHiddenItems)
                            if model.hiddenFeedItems.isEmpty == false {
                                Text("\(model.hiddenFeedItems.count) hidden")
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Refresh", systemImage: "arrow.clockwise", action: refresh)
                            .disabled(model.isRefreshing)
                    }
                }
            }
            .overlay {
                if model.isRefreshing {
                    ProgressView("Refreshing…")
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
