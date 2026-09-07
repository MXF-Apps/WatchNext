import Foundation
import WatchNextLogging

extension WatchNextLogLevel {
    var localizedDisplayName: String {
        switch self {
        case .debug: String(localized: .diagnosticsLevelDebugLabel)
        case .info: String(localized: .diagnosticsLevelInfoLabel)
        case .notice: String(localized: .diagnosticsLevelNoticeLabel)
        case .warning: String(localized: .diagnosticsLevelWarningLabel)
        case .error: String(localized: .diagnosticsLevelErrorLabel)
        case .fault: String(localized: .diagnosticsLevelFaultLabel)
        case .off: String(localized: .diagnosticsLevelOffLabel)
        }
    }
}
