import Foundation

public struct SonarrClient: SonarrServicing {
    private let baseURL: URL
    private let apiKey: String
    private let transport: any HTTPTransport

    public init(baseURL: URL, apiKey: String, transport: any HTTPTransport = URLSessionTransport()) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.transport = transport
    }

    public func testConnection() async throws -> ServiceHealth {
        let data = try await get(path: "/api/v3/system/status")
        do {
            let status = try JSONDecoder().decode(StatusDTO.self, from: data)
            return ServiceHealth(name: status.appName ?? "Sonarr", version: status.version)
        } catch let error as DecodingError {
            logger.error("Could not decode Sonarr status.", error: error, category: "Sonarr")
            throw NetworkError.decoding("Sonarr status")
        }
    }

    public func fetchEpisodes(recentSince: Date, futureThrough: Date) async throws -> [SonarrEpisode] {
        async let historyData = get(
            path: "/api/v3/history",
            queryItems: [
                .init(name: "page", value: "1"),
                .init(name: "pageSize", value: "250"),
                .init(name: "sortKey", value: "date"),
                .init(name: "sortDirection", value: "descending"),
                // The v3 API binds eventType as int[]; 3 is DownloadFolderImported in EpisodeHistoryEventType.
                .init(name: "eventType", value: "3"),
                .init(name: "includeSeries", value: "true"),
                .init(name: "includeEpisode", value: "true")
            ]
        )
        async let calendarData = get(
            path: "/api/v3/calendar",
            queryItems: [
                .init(name: "start", value: DateCoding.queryString(recentSince)),
                .init(name: "end", value: DateCoding.queryString(futureThrough)),
                .init(name: "includeSeries", value: "true"),
                .init(name: "includeEpisodeFile", value: "true")
            ]
        )

        do {
            let history = try JSONDecoder().decode(HistoryPageDTO.self, from: await historyData)
            let calendar = try JSONDecoder().decode([EpisodeDTO].self, from: await calendarData)
            let imported = history.records.compactMap { record -> SonarrEpisode? in
                guard let importedDate = DateCoding.parse(record.date), importedDate >= recentSince else {
                    return nil
                }
                return map(record: record, importedDate: importedDate)
            }
            let upcoming = calendar.map { map(episode: $0, importedDate: nil) }
            return deduplicate(imported + upcoming)
        } catch let error as DecodingError {
            logger.error("Could not decode Sonarr history/calendar.", error: error, category: "Sonarr")
            throw NetworkError.decoding("Sonarr history/calendar")
        }
    }

    private func get(path: String, queryItems: [URLQueryItem] = []) async throws -> Data {
        let url = try EndpointBuilder.makeURL(baseURL: baseURL, path: path, queryItems: queryItems)
        return try await transport.data(for: HTTPRequest(url: url, headers: ["X-Api-Key": apiKey]))
    }

    private func map(record: HistoryRecordDTO, importedDate: Date) -> SonarrEpisode? {
        guard let episode = record.episode, let series = record.series else { return nil }
        return map(
            episode: episode,
            seriesOverride: series,
            importedDate: importedDate,
            qualityOverride: record.quality?.quality?.name
        )
    }

    private func map(episode: EpisodeDTO, importedDate: Date?) -> SonarrEpisode {
        map(episode: episode, seriesOverride: episode.series, importedDate: importedDate, qualityOverride: nil)
    }

    private func map(
        episode: EpisodeDTO,
        seriesOverride: SeriesDTO?,
        importedDate: Date?,
        qualityOverride: String?
    ) -> SonarrEpisode {
        let series = seriesOverride
        return SonarrEpisode(
            id: episode.id,
            seriesID: episode.seriesId,
            seriesTitle: series?.title ?? "Unknown Series",
            episodeTitle: episode.title,
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber,
            monitored: episode.monitored ?? series?.monitored ?? false,
            hasFile: importedDate != nil || episode.hasFile == true,
            airDate: DateCoding.parse(episode.airDateUtc),
            importedDate: importedDate ?? DateCoding.parse(episode.episodeFile?.dateAdded),
            quality: qualityOverride ?? episode.episodeFile?.quality?.quality?.name,
            tvdbSeriesID: series?.tvdbId.map(String.init),
            tvdbEpisodeID: episode.tvdbId.map(String.init),
            tmdbSeriesID: series?.tmdbId.map(String.init),
            artworkURL: artworkURL(from: series?.images)
        )
    }

    private func artworkURL(from images: [ImageDTO]?) -> URL? {
        guard let image = images?.first(where: { $0.coverType == "poster" }) ?? images?.first else {
            return nil
        }
        if let remoteURL = image.remoteUrl.flatMap(URL.init(string:)) { return remoteURL }
        guard let path = image.url else { return nil }
        return try? EndpointBuilder.makeURL(baseURL: baseURL, path: path)
    }

    private func deduplicate(_ episodes: [SonarrEpisode]) -> [SonarrEpisode] {
        var byID: [Int: SonarrEpisode] = [:]
        for episode in episodes {
            if let existing = byID[episode.id], existing.importedDate != nil { continue }
            byID[episode.id] = episode
        }
        return Array(byID.values)
    }
}

private extension SonarrClient {
    struct StatusDTO: Decodable {
        let appName: String?
        let version: String?
    }

    struct HistoryPageDTO: Decodable {
        let records: [HistoryRecordDTO]
    }

    struct HistoryRecordDTO: Decodable {
        let date: String?
        let quality: QualityWrapperDTO?
        let series: SeriesDTO?
        let episode: EpisodeDTO?
    }

    struct EpisodeDTO: Decodable {
        let id: Int
        let seriesId: Int
        let title: String?
        let seasonNumber: Int
        let episodeNumber: Int
        let airDateUtc: String?
        let monitored: Bool?
        let hasFile: Bool?
        let tvdbId: Int?
        let series: SeriesDTO?
        let episodeFile: EpisodeFileDTO?
    }

    struct SeriesDTO: Decodable {
        let title: String?
        let monitored: Bool?
        let tvdbId: Int?
        let tmdbId: Int?
        let images: [ImageDTO]?
    }

    struct EpisodeFileDTO: Decodable {
        let dateAdded: String?
        let quality: QualityWrapperDTO?
    }

    struct QualityWrapperDTO: Decodable {
        let quality: QualityDTO?
    }

    struct QualityDTO: Decodable {
        let name: String?
    }

    struct ImageDTO: Decodable {
        let coverType: String?
        let url: String?
        let remoteUrl: String?
    }
}
