import SwiftUI
import WatchNextCore

struct FeedList: View {
    @EnvironmentObject private var model: WatchNextAppModel
    @AppStorage("WatchNext.Feed.readyExpanded") private var readyExpanded = true
    @AppStorage("WatchNext.Feed.comingSoonExpanded") private var comingSoonExpanded = true
    @State private var selection = Set<String>()

    var body: some View {
        let visible = model.visibleFeed
        let hidden = model.hiddenFeedItems
        let selectedVisible = (visible.ready + visible.comingSoon).filter { selection.contains($0.id) }
        let selectedSeries = selectedVisible.filter { $0.seriesHideKey != nil }
        let selectedHidden = hidden.filter { selection.contains($0.id) }
        let selecting: Binding<Set<String>>? = model.isSelectingItems ? $selection : nil
        List {
            if let issue = model.refreshIssue ?? model.feed.lastRefreshError.map(ActionableIssue.init(cachedRefreshError:)) {
                Section {
                    IssueRows(
                        issue: issue,
                        symbol: "wifi.exclamationmark",
                        messageAccessibilityLabel: String(localized: .feedRefreshErrorAccessibilityLabel(message: issue.message))
                    )
                } header: {
                    Text(String(localized: .feedRefreshErrorTitle))
                }
            }
            if model.demoMode {
                Section {
                    Label {
                        Text(String(localized: .feedDemoMessage))
                    } icon: {
                        Image(systemName: "sparkles")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            Section {
                Picker(String(localized: .feedFilterTitle), selection: $model.kindFilter) {
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
                        String(localized: .feedEmptyTitle),
                        systemImage: "play.rectangle.on.rectangle",
                        description: Text(emptyDescription(hiddenCount: hidden.count))
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                FeedSection(title: String(localized: .feedSectionReadyTitle), items: visible.ready, isExpanded: $readyExpanded, selection: selecting) { item in
                    HideActions(item: item) { scope in hide(item, scope: scope) }
                }
                FeedSection(title: String(localized: .feedSectionUpcomingTitle), items: visible.comingSoon, isExpanded: $comingSoonExpanded, selection: selecting) { item in
                    HideActions(item: item) { scope in hide(item, scope: scope) }
                }
            }
            if model.showsHiddenItems || model.isSelectingItems {
                FeedSection(title: String(localized: .feedSectionHiddenTitle), items: hidden, dimmed: true, selection: selecting) { item in
                    UnhideAction { unhide(item) }
                }
            }
            if let updated = model.feed.lastSuccessfulRefresh {
                Section {
                    LabeledContent(String(localized: .feedUpdatedLabel)) {
                        Text(updated, format: .relative(presentation: .named))
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .animation(.default, value: model.hiddenItems)
        .animation(.default, value: model.kindFilter)
        .animation(.default, value: model.isSelectingItems)
        .onChange(of: model.isSelectingItems) { _, selecting in
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
        case .all: parts.append(String(localized: .feedEmptyAllMessage))
        case .movies: parts.append(String(localized: .feedEmptyMoviesMessage))
        case .shows: parts.append(String(localized: .feedEmptyShowsMessage))
        }
        if hiddenCount > 0 {
            parts.append(String(localized: .feedEmptyHiddenMessage(count: hiddenCount)))
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
