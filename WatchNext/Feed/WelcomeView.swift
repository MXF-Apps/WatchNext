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
            Button("Try with sample data", systemImage: "sparkles", action: onTryDemo)
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
    }
}
