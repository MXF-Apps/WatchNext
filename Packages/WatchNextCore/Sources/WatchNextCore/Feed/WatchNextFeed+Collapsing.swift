public extension WatchNextFeed {
    /// Folds ready episodes of the same series and season into their earliest
    /// episode, so a whole imported season takes one row instead of ten.
    ///
    /// People watch a season in order, so the earliest unwatched episode is the
    /// one to surface; the row keeps the group's place in the list (the position
    /// of its first member, i.e. the newest import) and records how many later
    /// episodes it stands in for. Movies and episodes without season data pass
    /// through untouched. Coming Soon is left as one row per episode: each has
    /// its own air date, and a folded count next to a time read as noise.
    /// Apply after hiding so that hiding the surfaced episode reveals the next.
    func collapsingSeasons() -> WatchNextFeed {
        var copy = self
        copy.ready = MediaFeedItem.collapsingSeasons(ready)
        return copy
    }
}

public extension MediaFeedItem {
    /// Aired or released, not yet imported: shown in Coming Soon with a magnifier.
    var isAwaitingDownload: Bool { availability == .awaitingDownload }

    /// "and 4 more" when this row stands in for later episodes, else nil.
    var collapsedEpisodesDescription: String? {
        collapsedEpisodeCount.map { "and \($0) more" }
    }

    /// "×5" when this row stands in for later episodes: the total number of
    /// episodes folded into it, so it reads as a multiplier and cannot be
    /// confused with a "+N more" overflow count. Nil when nothing is folded.
    var collapsedEpisodesBadge: String? {
        collapsedEpisodeCount.map { "×\($0 + 1)" }
    }

    /// The `collapsingSeasons` algorithm for one section; see `WatchNextFeed`.
    static func collapsingSeasons(_ items: [MediaFeedItem]) -> [MediaFeedItem] {
        struct SeasonKey: Hashable {
            let seriesID: Int
            let season: Int
        }
        struct Group {
            var representative: MediaFeedItem
            var count: Int
        }

        var groups: [SeasonKey: Group] = [:]
        var order: [(key: SeasonKey?, item: MediaFeedItem)] = []

        for item in items {
            guard
                item.kind == .episode,
                let seriesID = item.sourceIDs.sonarrSeriesID,
                let season = item.seasonNumber,
                item.episodeNumber != nil
            else {
                order.append((nil, item))
                continue
            }
            let key = SeasonKey(seriesID: seriesID, season: season)
            if var group = groups[key] {
                group.count += 1
                if (item.episodeNumber ?? .max) < (group.representative.episodeNumber ?? .max) {
                    group.representative = item
                }
                groups[key] = group
            } else {
                groups[key] = Group(representative: item, count: 1)
                order.append((key, item))
            }
        }

        return order.map { entry in
            guard let key = entry.key, let group = groups[key] else { return entry.item }
            var representative = group.representative
            representative.collapsedEpisodeCount = group.count > 1 ? group.count - 1 : nil
            return representative
        }
    }
}
