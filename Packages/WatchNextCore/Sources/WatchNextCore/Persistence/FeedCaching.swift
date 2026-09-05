public protocol FeedCaching: Sendable {
    func load() async -> WatchNextFeed
    func saveSuccessful(_ feed: WatchNextFeed) async throws
    func recordFailure(_ message: String) async throws
}
