public actor KeychainCredentialStore: CredentialStoring {
    private let vault: any SecretVault

    public init(vault: any SecretVault = KeychainVault()) {
        self.vault = vault
    }

    public func value(for key: CredentialKey) async throws -> String? {
        try await vault.read(account: key.rawValue)
    }

    public func set(_ value: String?, for key: CredentialKey) async throws {
        guard let value, value.isEmpty == false else {
            try await vault.delete(account: key.rawValue)
            return
        }
        if try await vault.read(account: key.rawValue) == nil {
            try await vault.create(value, for: key.rawValue)
        } else {
            try await vault.update(value, for: key.rawValue)
        }
    }
}
