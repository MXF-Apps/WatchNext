import SwiftUI
import WatchNextCore

/// A problem shown to the user together with the one step that fixes it.
/// Errors are mapped here, in one place, so every screen gives the same advice.
struct ActionableIssue: Equatable {
    var message: String
    /// Plain-language next step, when one is known.
    var advice: String?
    var action: Action?

    enum Action: Equatable {
        /// Settings › Servers, scrolled to one server's section when known.
        case openServers(ServiceKind?)
        /// The iOS Settings app, for permissions.
        case openSystemSettings
    }
}

extension ActionableIssue {
    /// Guidance for a failed feed refresh.
    init(refreshError error: any Error) {
        if let failure = error as? ServiceFailure {
            self.init(
                message: failure.localizedDescription,
                advice: Self.advice(for: failure.underlying, service: failure.service),
                action: .openServers(failure.service)
            )
        } else {
            self.init(message: error.localizedDescription, advice: nil, action: .openServers(nil))
        }
    }

    /// Guidance for a refresh error read back from the cache, where only the
    /// message survived.
    init(cachedRefreshError message: String) {
        self.init(message: message, advice: nil, action: .openServers(nil))
    }

    /// Guidance when the Local Network probe could not decide.
    init(localNetworkFailure failure: LocalNetworkProbeFailure) {
        switch failure {
        case .notAuthorized:
            self.init(
                message: String(localized: .issueLocalNetworkNoAuthMessage),
                advice: String(localized: .issueLocalNetworkNoAuthAdvice),
                action: .openSystemSettings
            )
        case .timeout:
            self.init(
                message: String(localized: .issueLocalNetworkTimeoutMessage),
                advice: String(localized: .issueLocalNetworkTimeoutAdvice),
                action: .openSystemSettings
            )
        case .failed(let reason):
            self.init(
                message: String(localized: .issueLocalNetworkFailedMessage(reason: reason)),
                advice: String(localized: .issueLocalNetworkTimeoutAdvice),
                action: .openSystemSettings
            )
        }
    }

    private static func advice(for error: any Error, service: ServiceKind) -> String? {
        switch error {
        case NetworkError.unauthorized:
            String(localized: .issueAdviceUnauthorized(service: service.name))
        case NetworkError.missingConfiguration:
            String(localized: .issueAdviceMissingConfiguration(service: service.name))
        case NetworkError.invalidURL, is URLError:
            String(localized: .issueAdviceUnreachable(service: service.name))
        case NetworkError.server, NetworkError.invalidResponse, NetworkError.decoding:
            String(localized: .issueAdviceServerError(service: service.name))
        default:
            nil
        }
    }
}

/// Message, advice, and action rows for a Form or List section.
struct IssueRows: View {
    let issue: ActionableIssue
    var symbol = "exclamationmark.triangle.fill"
    var color: Color = .red
    /// VoiceOver text for the message row when the visible text needs context.
    var messageAccessibilityLabel: String? = nil

    var body: some View {
        Label {
            Text(issue.message)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(color)
        }
        .font(.callout)
        .accessibilityLabel(messageAccessibilityLabel ?? issue.message)
        if let advice = issue.advice {
            Text(advice)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        IssueActionButton(issue: issue)
    }
}

/// Performs an issue's action: in-app navigation or the iOS Settings app.
struct IssueActionButton: View {
    let issue: ActionableIssue
    @EnvironmentObject private var model: WatchNextAppModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        if let action = issue.action {
            Button {
                switch action {
                case .openServers(let service):
                    model.openServers(focusing: service)
                case .openSystemSettings:
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            } label: {
                switch action {
                case .openServers:
                    Label(String(localized: .issueActionOpenServersButton), systemImage: "wrench.and.screwdriver")
                case .openSystemSettings:
                    Label(String(localized: .settingsNetworkOpenSettingsButton), systemImage: "gear")
                }
            }
        }
    }
}
