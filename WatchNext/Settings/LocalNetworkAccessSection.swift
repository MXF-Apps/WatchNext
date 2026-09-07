import SwiftUI

/// Explains the Local Network permission and offers the one action that fits
/// the current state: ask for it, or open Settings after a refusal.
struct LocalNetworkAccessSection: View {
    let access: LocalNetworkAccess
    let request: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            switch access {
            case .denied:
                Label {
                    Text("Local network access is turned off, so servers on your home network cannot be reached.")
                } icon: {
                    Image(systemName: "wifi.exclamationmark")
                        .foregroundStyle(.orange)
                }
                Button("Open Settings", systemImage: "gear") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            case .unknown, .checking, .granted:
                Text("WatchNext talks to Sonarr, Radarr and Jellyfin on your home network. iOS asks once before an app may reach devices on the local network. Allow it, then add your servers.")
                Button(action: request) {
                    if access == .checking {
                        HStack {
                            ProgressView()
                            Text("Waiting for permission…")
                        }
                    } else {
                        Label("Allow Local Network Access", systemImage: "network")
                    }
                }
                .disabled(access == .checking)
            }
        } header: {
            Text("Local Network")
        } footer: {
            switch access {
            case .denied:
                Text("Turn on Local Network for WatchNext under Settings › Apps › WatchNext, or Privacy & Security › Local Network. The server fields below stay usable for servers reachable over the internet.")
            case .unknown, .checking, .granted:
                Text("If you decline, WatchNext only reaches servers over the internet, and you can change your mind later in the iOS Settings app.")
            }
        }
    }
}
