import WidgetKit
import WatchNextCore

struct WatchNextTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WatchNextEntry {
        WatchNextEntry(date: .now, feed: .placeholder, artwork: [:])
    }

    func snapshot(
        for configuration: WatchNextConfigurationIntent,
        in context: Context
    ) async -> WatchNextEntry {
        let feed = context.isPreview
            ? WatchNextFeed.placeholder
            : await WatchNextDependencies.live.feedService.cachedFeed()
        return await entry(for: feed, configuration: configuration, context: "snapshot")
    }

    func timeline(
        for configuration: WatchNextConfigurationIntent,
        in context: Context
    ) async -> Timeline<WatchNextEntry> {
        let service = WatchNextDependencies.live.feedService
        let feed: WatchNextFeed
        do {
            feed = try await service.refresh()
        } catch {
            logger.error("Widget timeline refresh failed; loading cached data.", error: error, category: "Widget")
            feed = await service.cachedFeed()
        }
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        return Timeline(entries: [await entry(for: feed, configuration: configuration, context: "timeline")], policy: .after(nextRefresh))
    }

    private func entry(
        for feed: WatchNextFeed,
        configuration: WatchNextConfigurationIntent,
        context: String
    ) async -> WatchNextEntry {
        logger.debug(
            "Building entry for \(context): density \(configuration.rowDensity.rawValue) (raw \"\(configuration.density ?? "nil")\"), kind \(configuration.kindFilter.rawValue) (raw \"\(configuration.kind ?? "nil")\"), artwork \(configuration.showsArtwork), titles \(configuration.showsSectionTitles).",
            category: "Widget"
        )
        // Hidden entries live in the App Group, so the widget honors the same list as the app.
        let feed = feed
            .hiding(await WatchNextDependencies.live.hiddenItemStore.hidden())
            .filtering(configuration.kindFilter)
            .collapsingSeasons()
        var artwork: [String: Data] = [:]
        // Only the large family draws artwork, up to 8 ready + 4 upcoming rows.
        for item in feed.ready.prefix(8) + feed.comingSoon.prefix(4) {
            guard let key = item.artworkCacheKey else { continue }
            if let data = await ArtworkDataStore.shared.data(for: key) {
                artwork[key] = data
            }
        }
        return WatchNextEntry(
            date: .now,
            feed: feed,
            artwork: artwork,
            density: configuration.rowDensity,
            kindFilter: configuration.kindFilter,
            showsArtwork: configuration.showsArtwork,
            showsSectionTitles: configuration.showsSectionTitles
        )
    }
}

private extension WatchNextFeed {
    /// Fictional sample content for the widget gallery and placeholders; never
    /// real titles, so previews and screenshots carry no third-party media.
    static let placeholder = WatchNextFeed(
        ready: [
            MediaFeedItem(
                id: "placeholder-ready-1",
                kind: .episode,
                title: "Harbor Lights",
                subtitle: "S02E01 — North Pier",
                availability: .ready,
                importedDate: .now,
                qualityDescription: "1080p",
                sourceIDs: .init(sonarrSeriesID: 1),
                seasonNumber: 2,
                episodeNumber: 1,
                collapsedEpisodeCount: 5
            ),
            MediaFeedItem(
                id: "placeholder-ready-2",
                kind: .movie,
                title: "Paper Meridian",
                subtitle: "Movie",
                availability: .ready,
                importedDate: .now,
                qualityDescription: "2160p"
            )
        ],
        comingSoon: [
            MediaFeedItem(
                id: "placeholder-coming",
                kind: .episode,
                title: "Ninefold Station",
                subtitle: "S03E10 — Pressure Drop",
                availability: .comingSoon,
                releaseDate: Calendar.current.date(byAdding: .day, value: 2, to: .now),
                sourceIDs: .init(sonarrSeriesID: 3),
                seasonNumber: 3,
                episodeNumber: 10
            )
        ],
        lastSuccessfulRefresh: .now
    )
}
