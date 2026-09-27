/// Keys the app writes to the standard defaults, listed in one place so
/// "Erase All Data" clears every one of them.
enum AppStorageKey {
    static let feedReadyExpanded = "WatchNext.Feed.readyExpanded"
    static let feedComingSoonExpanded = "WatchNext.Feed.comingSoonExpanded"
    static let feedKindFilter = "WatchNext.FeedKindFilter"
    static let localNetworkAccess = "WatchNext.LocalNetwork.access"

    static let all = [feedReadyExpanded, feedComingSoonExpanded, feedKindFilter, localNetworkAccess]
}
