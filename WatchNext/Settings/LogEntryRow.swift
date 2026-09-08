import SwiftUI
import WatchNextAppearance
import WatchNextCore
import WatchNextLogging

struct LogEntryRow: View {
    @Environment(\.palette) private var palette
    let entry: WatchNextLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.level.localizedDisplayName.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(levelColor)
                Text(entry.category)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(entry.timestamp, format: .dateTime.hour().minute().second())
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if let message = entry.message {
                Text(message)
                    .font(.callout)
                    .textSelection(.enabled)
            }
            if let error = entry.error {
                Text(verbatim: "\(error.domain) (\(error.code)): \(error.description)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var levelColor: Color {
        switch entry.level {
        case .debug, .info, .notice: .secondary
        case .warning: palette.caution
        case .error, .fault: palette.alert
        case .off: .secondary
        }
    }
}
