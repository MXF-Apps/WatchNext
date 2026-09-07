import SwiftUI

/// First-run empty state: no servers configured and demo mode off.
///
/// A plain VStack rather than ContentUnavailableView with actions: inside a
/// List row the latter let its button stretch to the row's height.
struct WelcomeView: View {
    let onTryDemo: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.rectangle.on.rectangle")
                .font(.system(size: 44))
                .accessibilityHidden(true)
                .foregroundStyle(.secondary)
            Text(String(localized: .feedWelcomeTitle))
                .font(.title2.weight(.semibold))
            Text(String(localized: .feedWelcomeMessage))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onTryDemo) {
                // Not a Label: List rows drop its icon by default, and its
                // title-and-icon style pads the icon too far from the text.
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text(String(localized: .feedWelcomeDemoButton))
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
    }
}
