import SwiftUI
import WatchNextCore

struct FeedSection<Actions: View>: View {
    let title: String
    let items: [MediaFeedItem]
    var dimmed = false
    /// When set, the header shows the row count and a chevron, and tapping it
    /// collapses or expands the section.
    var isExpanded: Binding<Bool>? = nil
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
            Text("No items")
                .foregroundStyle(.secondary)
        } else {
            ForEach(items) { item in
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
                Text("(\(count))")
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
        .accessibilityLabel("\(title), \(count) items")
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(isExpanded ? "Collapses the section" : "Expands the section")
    }
}
