import Foundation

public struct WatchNextFeed: Codable, Hashable, Sendable {
    public var ready: [MediaFeedItem]
    public var comingSoon: [MediaFeedItem]
    public var downloading: [MediaFeedItem]
    public var lastSuccessfulRefresh: Date?
    public var lastRefreshAttempt: Date?
    public var lastRefreshError: String?

    public init(
        ready: [MediaFeedItem] = [],
        comingSoon: [MediaFeedItem] = [],
        downloading: [MediaFeedItem] = [],
        lastSuccessfulRefresh: Date? = nil,
        lastRefreshAttempt: Date? = nil,
        lastRefreshError: String? = nil
    ) {
        self.ready = ready
        self.comingSoon = comingSoon
        self.downloading = downloading
        self.lastSuccessfulRefresh = lastSuccessfulRefresh
        self.lastRefreshAttempt = lastRefreshAttempt
        self.lastRefreshError = lastRefreshError
    }

    public static let empty = WatchNextFeed()
}
