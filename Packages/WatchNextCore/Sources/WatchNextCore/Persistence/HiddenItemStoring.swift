public protocol HiddenItemStoring: Sendable {
    func hidden() async -> Set<HiddenItem>
    func hide(_ entry: HiddenItem) async throws
    /// Adds several entries with a single write.
    func hide(contentsOf entries: some Sequence<HiddenItem> & Sendable) async throws
    func unhide(_ entries: some Sequence<HiddenItem> & Sendable) async throws
    /// Drops entries that no longer match anything in `feed` and returns what remains.
    @discardableResult
    func prune(keeping feed: WatchNextFeed) async throws -> Set<HiddenItem>
}
