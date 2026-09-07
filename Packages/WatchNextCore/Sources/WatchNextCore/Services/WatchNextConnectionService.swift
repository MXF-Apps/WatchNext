import Foundation

public actor WatchNextConnectionService {
    private let credentialStore: any CredentialStoring
    private let transport: any HTTPTransport

    public init(
        credentialStore: any CredentialStoring,
        transport: any HTTPTransport = URLSessionTransport()
    ) {
        self.credentialStore = credentialStore
        self.transport = transport
    }

    public func credential(_ key: CredentialKey) async throws -> String? {
        try await credentialStore.value(for: key)
    }

    public func hasCredential(_ key: CredentialKey) async throws -> Bool {
        try await credential(key)?.isEmpty == false
    }

    public func saveCredential(_ value: String, for key: CredentialKey) async throws {
        guard value.isEmpty == false else { return }
        try await credentialStore.set(value, for: key)
    }

    public func testSonarr(baseURL: URL, apiKey: String?) async throws -> ServiceHealth {
        let key = try await resolved(apiKey, key: .sonarrAPIKey, label: String(localized: "settings.missing.sonarrKey.label", defaultValue: "the Sonarr API key", bundle: .module))
        return try await SonarrClient(baseURL: baseURL, apiKey: key, transport: transport).testConnection()
    }

    public func testRadarr(baseURL: URL, apiKey: String?) async throws -> ServiceHealth {
        let key = try await resolved(apiKey, key: .radarrAPIKey, label: String(localized: "settings.missing.radarrKey.label", defaultValue: "the Radarr API key", bundle: .module))
        return try await RadarrClient(baseURL: baseURL, apiKey: key, transport: transport).testConnection()
    }

    public func authenticateJellyfin(
        baseURL: URL,
        username: String,
        password: String
    ) async throws -> JellyfinAuthentication {
        let client = JellyfinClient(baseURL: baseURL, accessToken: "", transport: transport)
        let authentication = try await client.authenticate(username: username, password: password)
        try await credentialStore.set(authentication.accessToken, for: .jellyfinAccessToken)
        try await credentialStore.set(username, for: .jellyfinUsername)
        return authentication
    }

    public func saveAndTestJellyfinToken(baseURL: URL, token: String?) async throws -> ServiceHealth {
        let resolvedToken = try await resolved(
            token,
            key: .jellyfinAccessToken,
            label: String(localized: "settings.missing.jellyfinToken.label", defaultValue: "the Jellyfin token", bundle: .module)
        )
        if let token, token.isEmpty == false {
            try await credentialStore.set(token, for: .jellyfinAccessToken)
        }
        return try await JellyfinClient(
            baseURL: baseURL,
            accessToken: resolvedToken,
            transport: transport
        ).testConnection()
    }

    public func fetchJellyfinUsers(baseURL: URL, token: String? = nil) async throws -> [JellyfinUser] {
        let resolvedToken = try await resolved(
            token,
            key: .jellyfinAccessToken,
            label: String(localized: "settings.missing.jellyfinToken.label", defaultValue: "the Jellyfin token", bundle: .module)
        )
        return try await JellyfinClient(
            baseURL: baseURL,
            accessToken: resolvedToken,
            transport: transport
        ).fetchUsers()
    }

    private func resolved(
        _ proposedValue: String?,
        key: CredentialKey,
        label: String
    ) async throws -> String {
        if let proposedValue, proposedValue.isEmpty == false {
            return proposedValue
        }
        if let stored = try await credentialStore.value(for: key), stored.isEmpty == false {
            return stored
        }
        throw NetworkError.missingConfiguration(label)
    }
}
