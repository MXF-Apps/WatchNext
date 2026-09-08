import SwiftUI
import WatchNextAppearance

/// Top banner for Settings feedback. Text stays `.primary` on a tinted
/// material so it reads in both color schemes; the color carries the meaning
/// through the icon, fill, and border. A tap dismisses it.
struct SettingsStatusBanner: View {
    @Environment(\.palette) private var palette
    let message: String
    let isError: Bool
    var onDismiss: () -> Void = {}

    private var tint: Color { isError ? palette.alert : palette.ready }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(tint)
            Text(message)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            Image(systemName: "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .font(.callout.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(tint.opacity(0.16))
                .background(.thickMaterial, in: .rect(cornerRadius: 14))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
        .contentShape(.rect)
        .onTapGesture(perform: onDismiss)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isError ? String(localized: .settingsBannerErrorAccessibilityLabel(message: message)) : String(localized: .settingsBannerSuccessAccessibilityLabel(message: message)))
        .accessibilityHint(String(localized: .settingsBannerDismissAccessibilityHint))
        .accessibilityAddTraits(.isButton)
    }
}
