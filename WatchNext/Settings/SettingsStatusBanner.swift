import SwiftUI

struct SettingsStatusBanner: View {
    let message: String
    let isError: Bool

    var body: some View {
        Label(message, systemImage: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
            .font(.callout.weight(.semibold))
            .foregroundStyle(isError ? .red : .green)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .shadow(radius: 4, y: 2)
            .accessibilityLabel(isError ? String(localized: .settingsBannerErrorAccessibilityLabel(message: message)) : String(localized: .settingsBannerSuccessAccessibilityLabel(message: message)))
    }
}
