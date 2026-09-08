import SwiftUI
import WatchNextAppearance

/// Batch actions for the feed's selection mode, shown above the list in place
/// of the tab bar. Each button carries the number of selected rows it applies to.
///
/// The bar sits on the card surface, not a translucent material, and disabled
/// buttons use the palette's muted color instead of the system dimming, so the
/// idle state stays readable over a strong wash and is covered by the palette
/// contrast tests.
struct SelectionActionBar: View {
    let hideCount: Int
    let hideSeriesCount: Int
    let unhideCount: Int
    let onHide: () -> Void
    let onHideSeries: () -> Void
    let onUnhide: () -> Void
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            action(String(localized: .feedActionsHideButton), count: hideCount, systemImage: "eye.slash", color: palette.caution, role: .destructive, onHide)
            action(String(localized: .feedActionsHideSeriesButton), count: hideSeriesCount, systemImage: "tv.slash", color: palette.alert, role: .destructive, onHideSeries)
            action(String(localized: .feedActionsUnhideButton), count: unhideCount, systemImage: "eye", color: palette.ready, role: nil, onUnhide)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(AppearanceSettings.card(for: colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.quaternary)
                .frame(height: 1)
        }
    }

    private func action(
        _ title: String,
        count: Int,
        systemImage: String,
        color: Color,
        role: ButtonRole?,
        _ perform: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: perform) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(String(localized: .feedSelectionActionLabel(title: title, count: count)))
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(SelectionActionButtonStyle(color: color, muted: palette.muted))
        .disabled(count == 0)
        .accessibilityLabel(String(localized: .feedSelectionActionAccessibilityLabel(title: title, count: count)))
    }
}

/// Bordered look whose disabled state keeps full opacity and switches to the
/// muted palette color, instead of the system's translucent dimming.
private struct SelectionActionButtonStyle: ButtonStyle {
    let color: Color
    let muted: Color
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let tone = isEnabled ? color : muted
        configuration.label
            .foregroundStyle(tone)
            .background(tone.opacity(isEnabled ? 0.14 : 0.08), in: .rect(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
