import SwiftUI

/// Explains the Local Network permission and offers the one action that fits
/// the current state: ask for it, or open Settings after a refusal.
struct LocalNetworkAccessSection: View {
    let access: LocalNetworkAccess
    /// Why the last check could not decide, shown under the button.
    var issue: ActionableIssue? = nil
    let request: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            switch access {
            case .denied:
                Label {
                    Text(String(localized: .settingsNetworkDeniedMessage))
                } icon: {
                    Image(systemName: "wifi.exclamationmark")
                        .foregroundStyle(.orange)
                }
                Button(String(localized: .settingsNetworkOpenSettingsButton), systemImage: "gear") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            case .unknown, .checking, .granted:
                Text(String(localized: .settingsNetworkExplanationMessage))
                Button(action: request) {
                    if access == .checking {
                        HStack {
                            ProgressView()
                            Text(String(localized: .settingsNetworkWaitingLabel))
                        }
                    } else {
                        Label(String(localized: .settingsNetworkAllowButton), systemImage: "network")
                    }
                }
                .disabled(access == .checking)
                if let issue {
                    IssueRows(issue: issue, symbol: "wifi.exclamationmark", color: .orange)
                }
            }
        } header: {
            Text(String(localized: .settingsNetworkTitle))
        } footer: {
            switch access {
            case .denied:
                Text(String(localized: .settingsNetworkDeniedFooter))
            case .unknown, .checking, .granted:
                Text(String(localized: .settingsNetworkFooter))
            }
        }
    }
}
