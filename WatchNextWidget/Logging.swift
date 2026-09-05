import WatchNextLogging

/// Widget-wide logger so call sites read `logger.info(...)` instead of `WatchNextLogger.shared.info(...)`.
let logger = WatchNextLogger.shared
