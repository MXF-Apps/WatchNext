import Foundation
import Testing
import WatchNextLogging

@Suite("WatchNext logger", .serialized)
struct WatchNextLoggerTests {
    @Test("Synchronous submissions retain their accepted order")
    func retainsOrder() async {
        let logger = WatchNextLogger(historyLimit: 10)

        logger.debug("first", category: "Test")
        logger.info("second", category: "Test")
        logger.error("third", error: TestLogError.example, category: "Test")

        let entries = await logger.entries()
        #expect(entries.map(\.sequence) == [0, 1, 2])
        #expect(entries.compactMap(\.message) == ["first", "second", "third"])
        #expect(entries.last?.error?.description == TestLogError.example.localizedDescription)
    }

    @Test("Filtered levels are dropped without evaluating the message")
    func filtersBelowMinimumLevelLazily() async {
        let previous = WatchNextLogger.minimumLevel
        defer { WatchNextLogger.setMinimumLevel(previous) }
        WatchNextLogger.setMinimumLevel(.warning)

        let logger = WatchNextLogger(historyLimit: 10)
        var evaluations = 0
        func build(_ text: String) -> String {
            evaluations += 1
            return text
        }

        logger.debug(build("dropped debug"))
        logger.info(build("dropped info"))
        logger.warning(build("kept warning"))
        logger.error(build("kept error"))

        let entries = await logger.entries()
        #expect(evaluations == 2)
        #expect(entries.compactMap(\.message) == ["kept warning", "kept error"])
        #expect(entries.map(\.level) == [.warning, .error])
    }

    @Test("Level .off silences everything")
    func offSilencesEverything() async {
        let previous = WatchNextLogger.minimumLevel
        defer { WatchNextLogger.setMinimumLevel(previous) }
        WatchNextLogger.setMinimumLevel(.off)

        let logger = WatchNextLogger(historyLimit: 10)
        logger.error("ignored", error: TestLogError.example)

        let entries = await logger.entries()
        #expect(entries.isEmpty)
    }

    @Test("History retains only its configured tail")
    func limitsHistory() async {
        let logger = WatchNextLogger(historyLimit: 2)

        logger.debug("first")
        logger.debug("second")
        logger.debug("third")

        let entries = await logger.entries()
        #expect(entries.compactMap(\.message) == ["second", "third"])
    }
}

private enum TestLogError: LocalizedError {
    case example

    var errorDescription: String? { "Example failure" }
}
