import Foundation

public enum WatchNextLogLevel: Int, Codable, CaseIterable, Comparable, Hashable, Sendable {
    case debug = 0
    case info
    case notice
    case warning
    case error
    case fault
    case off

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var displayName: String {
        switch self {
        case .debug: "Debug"
        case .info: "Info"
        case .notice: "Notice"
        case .warning: "Warning"
        case .error: "Error"
        case .fault: "Fault"
        case .off: "Off"
        }
    }
}
