import SwiftUI
import WatchNextCore

struct FeedList: View {
    @EnvironmentObject private var model: WatchNextAppModel
    @AppStorage("WatchNext.Feed.readyExpanded") private var readyExpanded = true
    @AppStorage("WatchNext.Feed.comingSoonExpanded") private var comingSoonExpanded = true
    @State private var selection = Set<String>()
    @State private var editMode: EditMode = .inactive

    var body: some View {
        let visible = model.visibleFeed
        let hidden = model.hiddenFeedItems
        let selectedVisible = (visible.ready + visible.comingSoon).filter { selection.contains($0.id) }
        let selectedSeries = selectedVisible.filter { $0.seriesHideKey != nil }
        let selectedHidden = hidden.filter { selection.contains($0.id) }
        List(selection: $selection) {
            if let message = model.refreshError ?? model.feed.lastRefreshError {
                Section {
                    Label(message, systemImage: "wifi.exclamationmark")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .accessibilityLabel("Refresh failed. \(message)")
                } header: {
                    Text("Refresh Failed")
                }
            }
            if model.demoMode {
                Section {
                    Label {
                        Text("Demo data. This is a fictional library; turn it off in Settings › Demo.")
                    } icon: {
                        Image(systemName: "sparkles")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            Section {
                Picker("Show", selection: $model.kindFilter) {
                    ForEach(FeedKindFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            if visible.ready.isEmpty && visible.comingSoon.isEmpty {
                if model.hasLoadedFeed, model.hasServerConfiguration == false, model.demoMode == false {
                    WelcomeView {
                        Task { await model.setDemoMode(true) }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else if model.hasLoadedFeed {
                    ContentUnavailableView(
                        "Nothing to Show Yet",
                        systemImage: "play.rectangle.on.rectangle",
                        description: Text(emptyDescription(hiddenCount: hidden.count))
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                FeedSection(title: "Ready to Watch", items: visible.ready, isExpanded: $readyExpanded) { item in
                    HideActions(item: item) { scope in hide(item, scope: scope) }
                }
                FeedSection(title: "Coming Soon", items: visible.comingSoon, isExpanded: $comingSoonExpanded) { item in
                    HideActions(item: item) { scope in hide(item, scope: scope) }
                }
            }
            if model.showsHiddenItems || model.isSelectingItems {
                FeedSection(title: "Hidden", items: hidden, dimmed: true) { item in
                    UnhideAction { unhide(item) }
                }
            }
            if let updated = model.feed.lastSuccessfulRefresh {
                Section {
                    LabeledContent("Last updated") {
                        Text(updated, format: .relative(presentation: .named))
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .animation(.default, value: model.hiddenItems)
        .animation(.default, value: model.kindFilter)
        .environment(\.editMode, $editMode)
        .onChange(of: model.isSelectingItems) { _, selecting in
            withAnimation { editMode = selecting ? .active : .inactive }
            if selecting == false { selection.removeAll() }
        }
        .toolbar(model.isSelectingItems ? .hidden : .visible, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if model.isSelectingItems {
                SelectionActionBar(
                    hideCount: selectedVisible.count,
                    hideSeriesCount: selectedSeries.count,
                    unhideCount: selectedHidden.count,
                    onHide: { apply { await model.hide(selectedVisible, scope: .item) } },
                    onHideSeries: { apply { await model.hide(selectedSeries, scope: .series) } },
                    onUnhide: { apply { await model.unhide(selectedHidden) } }
                )
            }
        }
        .refreshable {
            await model.refresh()
        }
    }

    /// Runs a batch action, then leaves selection mode.
    private func apply(_ action: @escaping @MainActor () async -> Void) {
        Task {
            await action()
            model.isSelectingItems = false
        }
    }

    private func emptyDescription(hiddenCount: Int) -> String {
        var parts: [String] = []
        switch model.kindFilter {
        case .all: parts.append("Pull to refresh, or review Settings and Diagnostics for details.")
        case .movies: parts.append("No movies right now. Switch to All or Shows, or pull to refresh.")
        case .shows: parts.append("No shows right now. Switch to All or Movies, or pull to refresh.")
        }
        if hiddenCount > 0 {
            parts.append("\(hiddenCount) hidden item\(hiddenCount == 1 ? "" : "s") can be shown from the toolbar menu.")
        }
        return parts.joined(separator: " ")
    }

    private func hide(_ item: MediaFeedItem, scope: HideScope) {
        Task { await model.hide(item, scope: scope) }
    }

    private func unhide(_ item: MediaFeedItem) {
        Task { await model.unhide(item) }
    }
}
