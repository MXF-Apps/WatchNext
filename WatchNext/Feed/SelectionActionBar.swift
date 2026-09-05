import SwiftUI

/// Batch actions for the feed's selection mode, shown above the list in place
/// of the tab bar. Each button carries the number of selected rows it applies to.
struct SelectionActionBar: View {
    let hideCount: Int
    let hideSeriesCount: Int
    let unhideCount: Int
    let onHide: () -> Void
    let onHideSeries: () -> Void
    let onUnhide: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            action("Hide", count: hideCount, systemImage: "eye.slash", role: .destructive, onHide)
            action("Hide Series", count: hideSeriesCount, systemImage: "tv.slash", role: .destructive, onHideSeries)
            action("Unhide", count: unhideCount, systemImage: "eye", role: nil, onUnhide)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func action(
        _ title: String,
        count: Int,
        systemImage: String,
        role: ButtonRole?,
        _ perform: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: perform) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text("\(title) (\(count))")
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .disabled(count == 0)
        .accessibilityLabel("\(title), \(count) selected")
    }
}
