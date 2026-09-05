import Foundation
import WatchNextLogging

public actor WatchNextCache: FeedCaching {
    private let fileURL: URL
    private let logger: WatchNextLogger

    public init(
        fileURL: URL? = nil,
        appGroupIdentifier: String = WatchNextConstants.appGroupIdentifier,
        logger: WatchNextLogger = .shared
    ) {
        self.logger = logger
        if let fileURL {
            self.fileURL = fileURL
        } else if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            self.fileURL = container.appending(path: WatchNextConstants.cacheFileName)
        } else {
            self.fileURL = URL.cachesDirectory.appending(path: WatchNextConstants.cacheFileName)
        }
    }

    public func load() -> WatchNextFeed {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch CocoaError.fileReadNoSuchFile {
            logger.debug("No cached feed was found.", category: "Cache")
            return .empty
        } catch {
            logger.error("Could not read the cached feed.", error: error, category: "Cache")
            return .empty
        }
        do {
            let feed = try decoder.decode(WatchNextFeed.self, from: data)
            logger.debug("Loaded the cached feed.", category: "Cache")
            return feed
        } catch {
            logger.error("Could not decode the cached feed.", error: error, category: "Cache")
            return .empty
        }
    }

    public func saveSuccessful(_ feed: WatchNextFeed) throws {
        var successful = feed
        let now = Date.now
        successful.lastSuccessfulRefresh = now
        successful.lastRefreshAttempt = now
        successful.lastRefreshError = nil
        try write(successful)
        logger.debug("Saved the successful feed cache.", category: "Cache")
    }

    public func recordFailure(_ message: String) throws {
        var cached = load()
        cached.lastRefreshAttempt = .now
        cached.lastRefreshError = message
        try write(cached)
        logger.debug("Recorded a failed refresh in the feed cache.", category: "Cache")
    }

    private func write(_ feed: WatchNextFeed) throws {
        let data = try encoder.encode(feed)
        try data.write(to: fileURL, options: .atomic)
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
