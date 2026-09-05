import Foundation

public struct RadarrClient: RadarrServicing {
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
            return ServiceHealth(name: status.appName ?? "Radarr", version: status.version)
        } catch let error as DecodingError {
            logger.error("Could not decode Radarr status.", error: error, category: "Radarr")
            throw NetworkError.decoding("Radarr status")
        }
    }

    public func fetchMovies(recentSince: Date, futureThrough: Date) async throws -> [RadarrMovie] {
        async let historyData = get(
            path: "/api/v3/history",
            queryItems: [
                .init(name: "page", value: "1"),
                .init(name: "pageSize", value: "250"),
                .init(name: "sortKey", value: "date"),
                .init(name: "sortDirection", value: "descending"),
                // The v3 API binds eventType as int[]; 3 is DownloadFolderImported in MovieHistoryEventType.
                .init(name: "eventType", value: "3"),
                .init(name: "includeMovie", value: "true")
            ]
        )
        async let calendarData = get(
            path: "/api/v3/calendar",
            queryItems: [
                .init(name: "start", value: DateCoding.queryString(recentSince)),
                .init(name: "end", value: DateCoding.queryString(futureThrough)),
                .init(name: "unmonitored", value: "false")
            ]
        )

        do {
            let history = try JSONDecoder().decode(HistoryPageDTO.self, from: await historyData)
            let calendar = try JSONDecoder().decode([MovieDTO].self, from: await calendarData)
            let imported = history.records.compactMap { record -> RadarrMovie? in
                guard
                    let movie = record.movie,
                    let importedDate = DateCoding.parse(record.date),
                    importedDate >= recentSince
                else { return nil }
                return map(movie: movie, importedDate: importedDate, qualityOverride: record.quality?.quality?.name)
            }
            let upcoming = calendar.map { map(movie: $0, importedDate: nil, qualityOverride: nil) }
            return deduplicate(imported + upcoming)
        } catch let error as DecodingError {
            logger.error("Could not decode Radarr history/calendar.", error: error, category: "Radarr")
            throw NetworkError.decoding("Radarr history/calendar")
        }
    }

    private func get(path: String, queryItems: [URLQueryItem] = []) async throws -> Data {
        let url = try EndpointBuilder.makeURL(baseURL: baseURL, path: path, queryItems: queryItems)
        return try await transport.data(for: HTTPRequest(url: url, headers: ["X-Api-Key": apiKey]))
    }

    private func map(movie: MovieDTO, importedDate: Date?, qualityOverride: String?) -> RadarrMovie {
        RadarrMovie(
            id: movie.id,
            title: movie.title,
            year: movie.year,
            monitored: movie.monitored,
            hasFile: importedDate != nil || movie.hasFile == true,
            releaseDate: preferredReleaseDate(for: movie),
            importedDate: importedDate ?? DateCoding.parse(movie.movieFile?.dateAdded),
            quality: qualityOverride ?? movie.movieFile?.quality?.quality?.name,
            tmdbID: movie.tmdbId.map(String.init),
            imdbID: movie.imdbId,
            artworkURL: artworkURL(from: movie.images)
        )
    }

    private func preferredReleaseDate(for movie: MovieDTO) -> Date? {
        DateCoding.parse(movie.digitalRelease)
            ?? DateCoding.parse(movie.physicalRelease)
            ?? DateCoding.parse(movie.inCinemas)
    }

    private func artworkURL(from images: [ImageDTO]?) -> URL? {
        guard let image = images?.first(where: { $0.coverType == "poster" }) ?? images?.first else {
            return nil
        }
        if let remoteURL = image.remoteUrl.flatMap(URL.init(string:)) { return remoteURL }
        guard let path = image.url else { return nil }
        return try? EndpointBuilder.makeURL(baseURL: baseURL, path: path)
    }

    private func deduplicate(_ movies: [RadarrMovie]) -> [RadarrMovie] {
        var byID: [Int: RadarrMovie] = [:]
        for movie in movies {
            if let existing = byID[movie.id], existing.importedDate != nil { continue }
            byID[movie.id] = movie
        }
        return Array(byID.values)
    }
}

private extension RadarrClient {
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
        let movie: MovieDTO?
    }

    struct MovieDTO: Decodable {
        let id: Int
        let title: String
        let year: Int?
        let monitored: Bool
        let hasFile: Bool?
        let digitalRelease: String?
        let physicalRelease: String?
        let inCinemas: String?
        let tmdbId: Int?
        let imdbId: String?
        let images: [ImageDTO]?
        let movieFile: MovieFileDTO?
    }

    struct MovieFileDTO: Decodable {
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
