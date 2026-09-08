import SwiftUI
import WatchNextAppearance
import WatchNextCore

struct ConnectionStatusView: View {
    @Environment(\.palette) private var palette
    let status: ConnectionStatus

    var body: some View {
        switch status {
        case .idle:
            EmptyView()
        case .testing:
            Label(String(localized: .settingsConnectionTestingLabel), systemImage: "hourglass")
                .foregroundStyle(.secondary)
        case .connected(let message):
            Label(message, systemImage: "checkmark.circle.fill")
                .foregroundStyle(palette.ready)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(palette.alert)
        }
    }
}
