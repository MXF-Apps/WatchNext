import SwiftUI
import WatchNextCore

struct ConnectionStatusView: View {
    let status: ConnectionStatus

    var body: some View {
        switch status {
        case .idle:
            EmptyView()
        case .testing:
            Label("Testing…", systemImage: "hourglass")
                .foregroundStyle(.secondary)
        case .connected(let message):
            Label(message, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
}
