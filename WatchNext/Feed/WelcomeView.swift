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
                .foregroundStyle(.secondary)
            Text("Welcome to WatchNext")
                .font(.title2.weight(.semibold))
            Text("Add your Sonarr, Radarr and Jellyfin servers in Settings, or look around with a fictional library first.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onTryDemo) {
                // Not a Label: List rows drop its icon by default, and its
                // title-and-icon style pads the icon too far from the text.
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Try with sample data")
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
