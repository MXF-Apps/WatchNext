import Foundation

public struct WatchNextLogEntry: Codable, Hashable, Identifiable, Sendable {
    public var id: UInt64 { sequence }

    public let sequence: UInt64
    public let timestamp: Date
    public let level: WatchNextLogLevel
    public let category: String
    public let message: String?
    public let error: WatchNextLogError?
    public let fileID: String
    public let function: String
    public let line: UInt
}
