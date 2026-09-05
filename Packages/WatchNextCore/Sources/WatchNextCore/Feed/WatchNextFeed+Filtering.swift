public extension WatchNextFeed {
    /// Every item across sections, in display order.
    var allItems: [MediaFeedItem] { ready + comingSoon + downloading }

    /// The feed without items matched by any hidden entry.
    func hiding(_ hidden: Set<HiddenItem>) -> WatchNextFeed {
        guard hidden.isEmpty == false else { return self }
        return mappingSections { $0.filter { $0.isHidden(by: hidden) == false } }
    }

    /// The items a set of hidden entries removes from this feed, in display order.
    func hiddenItems(matching hidden: Set<HiddenItem>) -> [MediaFeedItem] {
        guard hidden.isEmpty == false else { return [] }
        return allItems.filter { $0.isHidden(by: hidden) }
    }

    /// The feed narrowed to one media kind.
    func filtering(_ kind: FeedKindFilter) -> WatchNextFeed {
        guard kind != .all else { return self }
        return mappingSections { $0.filter { kind.includes($0.kind) } }
    }

    private func mappingSections(
        _ transform: ([MediaFeedItem]) -> [MediaFeedItem]
    ) -> WatchNextFeed {
        var copy = self
        copy.ready = transform(ready)
        copy.comingSoon = transform(comingSoon)
        copy.downloading = transform(downloading)
        return copy
    }
}
