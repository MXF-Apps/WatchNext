import Foundation
import Testing
@testable import WatchNextCore

@Suite("Credential persistence facade")
struct CredentialPersistenceTests {
    @Test("Credentials support create, read, update, and delete")
    func credentialCRUD() async throws {
        let store = KeychainCredentialStore(vault: InMemorySecretVault())

        try await store.set("first", for: .sonarrAPIKey)
        let created = try await store.value(for: .sonarrAPIKey)
        #expect(created == "first")

        try await store.set("updated", for: .sonarrAPIKey)
        let updated = try await store.value(for: .sonarrAPIKey)
        #expect(updated == "updated")

        try await store.set(nil, for: .sonarrAPIKey)
        let deleted = try await store.value(for: .sonarrAPIKey)
        #expect(deleted == nil)
    }

    @Test("Jellyfin login stores both the access token and username")
    func jellyfinLoginStoresIdentity() async throws {
        let store = KeychainCredentialStore(vault: InMemorySecretVault())
        let service = WatchNextConnectionService(
            credentialStore: store,
            transport: JellyfinAuthenticationTransport()
        )

        _ = try await service.authenticateJellyfin(
            baseURL: try #require(URL(string: "https://jellyfin.example")),
            username: "watcher",
            password: "not-persisted"
        )

        let username = try await service.credential(.jellyfinUsername)
        let token = try await service.credential(.jellyfinAccessToken)
        #expect(username == "watcher")
        #expect(token == "fixture-token")
    }

    @Test("Credential lookup errors are propagated")
    func lookupErrorsPropagate() async {
        let store = KeychainCredentialStore(vault: InMemorySecretVault(readError: .forced))
        let service = WatchNextConnectionService(credentialStore: store)

        do {
            _ = try await service.hasCredential(.radarrAPIKey)
            Issue.record("Expected the credential lookup to fail.")
        } catch VaultError.forced {
            // Expected.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

private enum VaultError: Error {
    case duplicate
    case missing
    case forced
}

private actor InMemorySecretVault: SecretVault {
    private var values: [String: String] = [:]
    private let readError: VaultError?

    init(readError: VaultError? = nil) {
        self.readError = readError
    }

    func create(_ value: String, for account: String) throws {
        guard values[account] == nil else { throw VaultError.duplicate }
        values[account] = value
    }

    func read(account: String) throws -> String? {
        if let readError { throw readError }
        return values[account]
    }

    func update(_ value: String, for account: String) throws {
        guard values[account] != nil else { throw VaultError.missing }
        values[account] = value
    }

    func delete(account: String) {
        values[account] = nil
    }
}

private struct JellyfinAuthenticationTransport: HTTPTransport {
    func data(for request: HTTPRequest) async throws -> Data {
        Data(
            #"{"AccessToken":"fixture-token","User":{"Id":"user-1","Name":"Watcher"}}"#.utf8
        )
    }
}
