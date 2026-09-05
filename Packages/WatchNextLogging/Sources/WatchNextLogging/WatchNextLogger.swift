import Foundation
import OSLog
import Synchronization

/// A synchronous, concurrency-safe logging facade backed by one ordered stream.
///
/// Logging calls never suspend. They take one non-blocking `Mutex` read to
/// compare against the minimum level and return early when filtered, so the
/// message autoclosure is evaluated only for entries that will be recorded. A
/// single consumer assigns sequence numbers and forwards entries to Unified
/// Logging in the order in which the shared continuation accepts them.
public final class WatchNextLogger: Sendable {
    public static let shared = WatchNextLogger()

    private struct Configuration: Sendable {
        var minimumLevel: WatchNextLogLevel = .debug
    }

    private struct Submission: Sendable {
        let timestamp: Date
        let level: WatchNextLogLevel
        let category: String
        let message: String?
        let error: WatchNextLogError?
        let fileID: String
        let function: String
        let line: UInt
    }

    private enum Command: Sendable {
        case submit(Submission)
        case entries(CheckedContinuation<[WatchNextLogEntry], Never>)
        case clear(CheckedContinuation<Void, Never>)
    }

    private actor Store {
        private let historyLimit: Int
        private let systemLogger: Logger
        private var history: [WatchNextLogEntry] = []
        private var nextSequence: UInt64 = 0

        init(historyLimit: Int) {
            self.historyLimit = historyLimit
            systemLogger = Logger(
                subsystem: Bundle.main.bundleIdentifier ?? "WatchNext",
                category: "WatchNext"
            )
        }

        func accept(_ command: Command) {
            switch command {
            case .submit(let submission):
                accept(submission)
            case .entries(let continuation):
                continuation.resume(returning: history)
            case .clear(let continuation):
                history.removeAll(keepingCapacity: true)
                continuation.resume()
            }
        }

        private func accept(_ submission: Submission) {
            let entry = WatchNextLogEntry(
                sequence: nextSequence,
                timestamp: submission.timestamp,
                level: submission.level,
                category: submission.category,
                message: submission.message,
                error: submission.error,
                fileID: submission.fileID,
                function: submission.function,
                line: submission.line
            )
            nextSequence &+= 1

            history.append(entry)
            if history.count > historyLimit {
                history.removeFirst(history.count - historyLimit)
            }

            writeToSystemLog(entry)
        }

        private func writeToSystemLog(_ entry: WatchNextLogEntry) {
            let rendered = Self.render(entry)
            switch entry.level {
            case .debug:
                systemLogger.debug("\(rendered, privacy: .public)")
            case .info:
                systemLogger.info("\(rendered, privacy: .public)")
            case .notice:
                systemLogger.notice("\(rendered, privacy: .public)")
            case .warning:
                systemLogger.warning("\(rendered, privacy: .public)")
            case .error:
                systemLogger.error("\(rendered, privacy: .public)")
            case .fault:
                systemLogger.fault("\(rendered, privacy: .public)")
            case .off:
                break
            }
        }

        private static func render(_ entry: WatchNextLogEntry) -> String {
            var components = ["[\(entry.category)]"]
            if let message = entry.message {
                components.append(message)
            }
            if let error = entry.error {
                components.append("\(error.domain)(\(error.code)): \(error.description)")
            }
            components.append("[\(entry.fileID):\(entry.line) \(entry.function)]")
            return components.joined(separator: " ")
        }
    }

    private static let configuration = Mutex(Configuration())

    private let continuation: AsyncStream<Command>.Continuation

    public init(historyLimit: Int = 1_000) {
        let (stream, continuation) = AsyncStream.makeStream(
            of: Command.self,
            bufferingPolicy: .unbounded
        )
        let store = Store(historyLimit: historyLimit)
        self.continuation = continuation

        Task { [stream, store] in
            for await command in stream {
                await store.accept(command)
            }
        }
    }

    deinit {
        continuation.finish()
    }

    public static var minimumLevel: WatchNextLogLevel {
        configuration.withLock { $0.minimumLevel }
    }

    public static func setMinimumLevel(_ level: WatchNextLogLevel) {
        configuration.withLock { $0.minimumLevel = level }
    }

    public nonisolated func debug(
        _ message: @autoclosure () -> String = "",
        error: (any Error)? = nil,
        category: String = "General",
        fileID: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(
            .debug,
            message(),
            error: error,
            category: category,
            fileID: fileID,
            function: function,
            line: line
        )
    }

    public nonisolated func info(
        _ message: @autoclosure () -> String = "",
        error: (any Error)? = nil,
        category: String = "General",
        fileID: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.info, message(), error: error, category: category, fileID: fileID, function: function, line: line)
    }

    public nonisolated func warning(
        _ message: @autoclosure () -> String = "",
        error: (any Error)? = nil,
        category: String = "General",
        fileID: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.warning, message(), error: error, category: category, fileID: fileID, function: function, line: line)
    }

    public nonisolated func notice(
        _ message: @autoclosure () -> String = "",
        error: (any Error)? = nil,
        category: String = "General",
        fileID: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.notice, message(), error: error, category: category, fileID: fileID, function: function, line: line)
    }

    public nonisolated func error(
        _ message: @autoclosure () -> String = "",
        error: (any Error)? = nil,
        category: String = "General",
        fileID: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.error, message(), error: error, category: category, fileID: fileID, function: function, line: line)
    }

    public nonisolated func log(
        _ level: WatchNextLogLevel,
        _ message: @autoclosure () -> String = "",
        error: (any Error)? = nil,
        category: String = "General",
        fileID: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        // Check the level first (non-suspending Mutex read) so a filtered call
        // never pays for building its message.
        guard Self.shouldRecord(level) else { return }
        let message = message()
        continuation.yield(
            .submit(Submission(
                timestamp: Date(),
                level: level,
                category: category,
                message: message.isEmpty ? nil : message,
                error: error.map { WatchNextLogError(error: $0) },
                fileID: fileID,
                function: function,
                line: line
            ))
        )
    }

    public func entries() async -> [WatchNextLogEntry] {
        await withCheckedContinuation { continuation in
            self.continuation.yield(.entries(continuation))
        }
    }

    public func clear() async {
        await withCheckedContinuation { continuation in
            self.continuation.yield(.clear(continuation))
        }
    }

    private static func shouldRecord(_ level: WatchNextLogLevel) -> Bool {
        configuration.withLock {
            $0.minimumLevel != .off && level >= $0.minimumLevel
        }
    }
}
