import Foundation

public struct LiveSourceLoader: SourceLoading {
    private let credentialStore: any CredentialStoring
    private let transport: any HTTPTransport

    public init(
        credentialStore: any CredentialStoring,
        transport: any HTTPTransport = URLSessionTransport()
    ) {
        self.credentialStore = credentialStore
        self.transport = transport
    }

    public func load(configuration: ServiceConfiguration) async throws -> SourceSnapshot {
        logger.info("Loading source data.", category: "Refresh")
        guard let sonarrURL = configuration.sonarrBaseURL else {
            throw NetworkError.missingConfiguration(String(localized: "settings.missing.sonarrURL.label", defaultValue: "the Sonarr URL", bundle: .module))
        }
        guard let radarrURL = configuration.radarrBaseURL else {
            throw NetworkError.missingConfiguration(String(localized: "settings.missing.radarrURL.label", defaultValue: "the Radarr URL", bundle: .module))
        }
        guard let jellyfinURL = configuration.jellyfinBaseURL else {
            throw NetworkError.missingConfiguration(String(localized: "settings.missing.jellyfinURL.label", defaultValue: "the Jellyfin URL", bundle: .module))
        }
        guard let userID = configuration.jellyfinUserID, userID.isEmpty == false else {
            throw NetworkError.missingConfiguration(String(localized: "settings.missing.jellyfinUser.label", defaultValue: "a Jellyfin user", bundle: .module))
        }
        let secrets = try await credentials()
        guard let sonarrKey = secrets[.sonarrAPIKey], sonarrKey.isEmpty == false else {
            throw NetworkError.missingConfiguration(String(localized: "settings.missing.sonarrKey.label", defaultValue: "the Sonarr API key", bundle: .module))
        }
        guard let radarrKey = secrets[.radarrAPIKey], radarrKey.isEmpty == false else {
            throw NetworkError.missingConfiguration(String(localized: "settings.missing.radarrKey.label", defaultValue: "the Radarr API key", bundle: .module))
        }
        guard let jellyfinToken = secrets[.jellyfinAccessToken], jellyfinToken.isEmpty == false else {
            throw NetworkError.missingConfiguration(String(localized: "settings.missing.jellyfinToken.label", defaultValue: "the Jellyfin token", bundle: .module))
        }
        logger.debug(
            "Resolved Sonarr, Radarr, and Jellyfin credentials without exposing their values.",
            category: "Refresh"
        )

        let now = Date.now
        let recentSince = configuration.recentStart(now: now)
        let futureThrough = configuration.futureEnd(now: now)
        let sonarr = SonarrClient(baseURL: sonarrURL, apiKey: sonarrKey, transport: transport)
        let radarr = RadarrClient(baseURL: radarrURL, apiKey: radarrKey, transport: transport)
        let jellyfin = JellyfinClient(baseURL: jellyfinURL, accessToken: jellyfinToken, transport: transport)

        async let episodes = sonarr.fetchEpisodes(recentSince: recentSince, futureThrough: futureThrough)
        async let movies = radarr.fetchMovies(recentSince: recentSince, futureThrough: futureThrough)
        async let library = jellyfin.fetchLibrary(userID: userID)
        let snapshot = try await SourceSnapshot(
            sonarrEpisodes: episodes,
            radarrMovies: movies,
            jellyfinItems: library
        )
        logger.info(
            "Loaded \(snapshot.sonarrEpisodes.count) Sonarr episodes, \(snapshot.radarrMovies.count) Radarr movies, and \(snapshot.jellyfinItems.count) Jellyfin items.",
            category: "Refresh"
        )
        return snapshot
    }

    public func credentials() async throws -> [CredentialKey: String] {
        var result: [CredentialKey: String] = [:]
        for key in CredentialKey.allCases {
            if let value = try await credentialStore.value(for: key) {
                result[key] = value
            }
        }
        return result
    }
}
