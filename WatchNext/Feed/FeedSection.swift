import SwiftUI
import WatchNextCore

struct FeedSection<Actions: View>: View {
    let title: String
    let items: [MediaFeedItem]
    var dimmed = false
    /// When set, the header shows the row count and a chevron, and tapping it
    /// collapses or expands the section.
    var isExpanded: Binding<Bool>? = nil
    /// Set while the user is selecting items. Rows then show a check circle
    /// and toggle on tap instead of offering swipe and context actions.
    /// Drawn by hand rather than through `List(selection:)`, because edit
    /// mode's swipe-to-select gesture swallowed vertical drags on the cells.
    var selection: Binding<Set<String>>? = nil
    @ViewBuilder let actions: (MediaFeedItem) -> Actions

    var body: some View {
        if let isExpanded {
            Section(isExpanded: isExpanded) {
                rows
            } header: {
                CollapsibleSectionHeader(title: title, count: items.count, isExpanded: isExpanded)
            }
        } else {
            Section(title) {
                rows
            }
        }
    }

    @ViewBuilder
    private var rows: some View {
        if items.isEmpty {
            Text(String(localized: .feedSectionEmptyMessage))
                .foregroundStyle(.secondary)
        } else {
            ForEach(items) { item in
                if let selection {
                    SelectableRow(isSelected: selection.wrappedValue.contains(item.id)) {
                        if selection.wrappedValue.contains(item.id) {
                            selection.wrappedValue.remove(item.id)
                        } else {
                            selection.wrappedValue.insert(item.id)
                        }
                    } content: {
                        MediaFeedRow(item: item)
                            .opacity(dimmed ? 0.55 : 1)
                    }
                } else {
                    MediaFeedRow(item: item)
                        .opacity(dimmed ? 0.55 : 1)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            actions(item)
                        }
                        .contextMenu {
                            actions(item)
                        }
                }
            }
        }
    }
}

/// "Ready to Watch (8)" with a chevron that points down while expanded.
struct CollapsibleSectionHeader: View {
    let title: String
    let count: Int
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.snappy) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                Text(verbatim: "(\(count.formatted()))")
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: .feedSectionCountAccessibilityLabel(title: title, count: count)))
        .accessibilityValue(isExpanded ? String(localized: .feedSectionExpandedAccessibilityValue) : String(localized: .feedSectionCollapsedAccessibilityValue))
        .accessibilityHint(isExpanded ? String(localized: .feedSectionCollapseAccessibilityHint) : String(localized: .feedSectionExpandAccessibilityHint))
    }
}

/// A row with a leading check circle that toggles on tap. A plain button, so
/// a drag that starts on it still scrolls the list.
private struct SelectableRow<Content: View>: View {
    let isSelected: Bool
    let toggle: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                    .contentTransition(.symbolEffect(.replace))
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.14) : nil)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .animation(.snappy, value: isSelected)
    }
}
