import Foundation
import WatchNextLogging

/// App Group–backed list of hidden media, shared by the app and the widget.
public actor HiddenItemStore: HiddenItemStoring {
    private let defaults: UserDefaults
    private let key = "WatchNext.HiddenItems"
    private let logger: WatchNextLogger

    public init(defaults: UserDefaults, logger: WatchNextLogger = .shared) {
        self.defaults = defaults
        self.logger = logger
    }

    public init(
        appGroupIdentifier: String = WatchNextConstants.appGroupIdentifier,
        logger: WatchNextLogger = .shared
    ) {
        if let defaults = UserDefaults(suiteName: appGroupIdentifier) {
            self.init(defaults: defaults, logger: logger)
        } else {
            logger.warning(
                "App Group \(appGroupIdentifier) is unavailable; hidden items use standard defaults.",
                category: "HiddenItems"
            )
            self.init(defaults: .standard, logger: logger)
        }
    }

    public func hidden() -> Set<HiddenItem> {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode(Set<HiddenItem>.self, from: data)
        } catch {
            logger.error("Could not decode hidden items; ignoring the stored list.", error: error, category: "HiddenItems")
            return []
        }
    }

    public func hide(_ entry: HiddenItem) throws {
        try hide(contentsOf: [entry])
    }

    public func hide(contentsOf entries: some Sequence<HiddenItem> & Sendable) throws {
        var current = hidden()
        let added = entries.filter { current.insert($0).inserted }
        guard added.isEmpty == false else { return }
        try save(current)
        logger.info("Hid \(added.map(describe).joined(separator: ", ")).", category: "HiddenItems")
    }

    public func unhide(_ entries: some Sequence<HiddenItem> & Sendable) throws {
        var current = hidden()
        let removed = entries.filter { current.remove($0) != nil }
        guard removed.isEmpty == false else { return }
        try save(current)
        logger.info("Unhid \(removed.map(describe).joined(separator: ", ")).", category: "HiddenItems")
    }

    @discardableResult
    public func prune(keeping feed: WatchNextFeed) throws -> Set<HiddenItem> {
        let current = hidden()
        guard current.isEmpty == false else { return current }
        let items = feed.allItems
        let kept = current.filter { entry in items.contains { entry.matches($0) } }
        let dropped = current.count - kept.count
        if dropped > 0 {
            try save(kept)
            logger.info(
                "Pruned \(dropped) hidden item\(dropped == 1 ? "" : "s") no longer in the feed; \(kept.count) remain.",
                category: "HiddenItems"
            )
        }
        return kept
    }

    private func save(_ entries: Set<HiddenItem>) throws {
        defaults.set(try JSONEncoder().encode(entries), forKey: key)
    }

    private func describe(_ entry: HiddenItem) -> String {
        switch entry {
        case .item(let id): "item \(id)"
        case .series(let seriesID): "series \(seriesID)"
        }
    }
}
