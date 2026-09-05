import Foundation

public struct JellyfinClient: JellyfinServicing {
    private let baseURL: URL
    private let accessToken: String
    private let transport: any HTTPTransport
    private let deviceID: String

    public init(
        baseURL: URL,
        accessToken: String,
        transport: any HTTPTransport = URLSessionTransport(),
        deviceID: String = "watchnext-ios"
    ) {
        self.baseURL = baseURL
        self.accessToken = accessToken
        self.transport = transport
        self.deviceID = deviceID
    }

    public func testConnection() async throws -> ServiceHealth {
        let data = try await send(path: "/System/Info")
        do {
            let status = try JSONDecoder().decode(SystemInfoDTO.self, from: data)
            return ServiceHealth(name: status.serverName ?? "Jellyfin", version: status.version)
        } catch let error as DecodingError {
            logger.error("Could not decode Jellyfin system info.", error: error, category: "Jellyfin")
            throw NetworkError.decoding("Jellyfin system info")
        }
    }

    public func authenticate(username: String, password: String) async throws -> JellyfinAuthentication {
        let payload = LoginRequestDTO(username: username, password: password)
        let body = try JSONEncoder().encode(payload)
        let data = try await send(
            path: "/Users/AuthenticateByName",
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: body,
            includeToken: false
        )
        do {
            let response = try JSONDecoder().decode(LoginResponseDTO.self, from: data)
            return JellyfinAuthentication(accessToken: response.accessToken, user: response.user)
        } catch let error as DecodingError {
            logger.error("Could not decode Jellyfin authentication.", error: error, category: "Jellyfin")
            throw NetworkError.decoding("Jellyfin authentication")
        }
    }

    public func fetchUsers() async throws -> [JellyfinUser] {
        let data = try await send(path: "/Users")
        do {
            return try JSONDecoder().decode([JellyfinUser].self, from: data)
        } catch let error as DecodingError {
            logger.error("Could not decode Jellyfin users.", error: error, category: "Jellyfin")
            throw NetworkError.decoding("Jellyfin users")
        }
    }

    public func fetchLibrary(userID: String) async throws -> [JellyfinMediaItem] {
        async let seriesData = send(
            path: "/Users/\(userID)/Items",
            queryItems: libraryQuery(includeItemTypes: "Series")
        )
        async let mediaData = send(
            path: "/Users/\(userID)/Items",
            queryItems: libraryQuery(includeItemTypes: "Movie,Episode")
        )

        do {
            let seriesPage = try JSONDecoder().decode(ItemsPageDTO.self, from: await seriesData)
            let mediaPage = try JSONDecoder().decode(ItemsPageDTO.self, from: await mediaData)
            let seriesProviders = Dictionary(
                uniqueKeysWithValues: seriesPage.items.map { ($0.id, $0.providerIds ?? [:]) }
            )
            return mediaPage.items.compactMap { item in
                map(item: item, seriesProviders: seriesProviders)
            }
        } catch let error as DecodingError {
            logger.error("Could not decode Jellyfin library.", error: error, category: "Jellyfin")
            throw NetworkError.decoding("Jellyfin library")
        }
    }

    private func libraryQuery(includeItemTypes: String) -> [URLQueryItem] {
        [
            .init(name: "Recursive", value: "true"),
            .init(name: "IncludeItemTypes", value: includeItemTypes),
            .init(name: "Fields", value: "ProviderIds,UserData,ProductionYear"),
            .init(name: "EnableUserData", value: "true"),
            .init(name: "ImageTypeLimit", value: "1"),
            .init(name: "EnableImageTypes", value: "Primary"),
            .init(name: "Limit", value: "10000")
        ]
    }

    private func send(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        includeToken: Bool = true
    ) async throws -> Data {
        let url = try EndpointBuilder.makeURL(baseURL: baseURL, path: path, queryItems: queryItems)
        var requestHeaders = headers
        requestHeaders["Authorization"] = authorizationHeader(includeToken: includeToken)
        return try await transport.data(
            for: HTTPRequest(method: method, url: url, headers: requestHeaders, body: body)
        )
    }

    private func authorizationHeader(includeToken: Bool) -> String {
        var value = "MediaBrowser Client=\"WatchNext\", Device=\"iOS\", DeviceId=\"\(deviceID)\", Version=\"1.0\""
        if includeToken, accessToken.isEmpty == false {
            value += ", Token=\"\(accessToken)\""
        }
        return value
    }

    private func map(
        item: ItemDTO,
        seriesProviders: [String: [String: String]]
    ) -> JellyfinMediaItem? {
        let kind: MediaKind
        switch item.type {
        case "Movie": kind = .movie
        case "Episode": kind = .episode
        default: return nil
        }
        let progress = item.userData?.playedPercentage.map { min(max($0 / 100, 0), 1) }
        return JellyfinMediaItem(
            id: item.id,
            kind: kind,
            name: item.name,
            seriesName: item.seriesName,
            productionYear: item.productionYear,
            seasonNumber: item.parentIndexNumber,
            episodeNumber: item.indexNumber,
            isPlayed: item.userData?.played ?? false,
            playbackProgress: progress,
            providerIDs: item.providerIds ?? [:],
            seriesProviderIDs: item.seriesId.flatMap { seriesProviders[$0] } ?? [:],
            artworkURL: imageURL(for: item.id)
        )
    }

    private func imageURL(for itemID: String) -> URL? {
        try? EndpointBuilder.makeURL(
            baseURL: baseURL,
            path: "/Items/\(itemID)/Images/Primary",
            queryItems: [
                .init(name: "maxWidth", value: "300"),
                .init(name: "quality", value: "80")
            ]
        )
    }
}

private extension JellyfinClient {
    struct SystemInfoDTO: Decodable {
        let serverName: String?
        let version: String?

        enum CodingKeys: String, CodingKey {
            case serverName = "ServerName"
            case version = "Version"
        }
    }

    struct LoginRequestDTO: Encodable {
        let username: String
        let password: String

        enum CodingKeys: String, CodingKey {
            case username = "Username"
            case password = "Pw"
        }
    }

    struct LoginResponseDTO: Decodable {
        let accessToken: String
        let user: JellyfinUser

        enum CodingKeys: String, CodingKey {
            case accessToken = "AccessToken"
            case user = "User"
        }
    }

    struct ItemsPageDTO: Decodable {
        let items: [ItemDTO]

        enum CodingKeys: String, CodingKey {
            case items = "Items"
        }
    }

    struct ItemDTO: Decodable {
        let id: String
        let type: String
        let name: String
        let seriesName: String?
        let seriesId: String?
        let productionYear: Int?
        let parentIndexNumber: Int?
        let indexNumber: Int?
        let providerIds: [String: String]?
        let userData: UserDataDTO?

        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case type = "Type"
            case name = "Name"
            case seriesName = "SeriesName"
            case seriesId = "SeriesId"
            case productionYear = "ProductionYear"
            case parentIndexNumber = "ParentIndexNumber"
            case indexNumber = "IndexNumber"
            case providerIds = "ProviderIds"
            case userData = "UserData"
        }
    }

    struct UserDataDTO: Decodable {
        let played: Bool?
        let playedPercentage: Double?

        enum CodingKeys: String, CodingKey {
            case played = "Played"
            case playedPercentage = "PlayedPercentage"
        }
    }
}
