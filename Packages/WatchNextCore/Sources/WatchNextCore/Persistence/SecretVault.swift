public protocol SecretVault: Sendable {
    func create(_ value: String, for account: String) async throws
    func read(account: String) async throws -> String?
    func update(_ value: String, for account: String) async throws
    func delete(account: String) async throws
}
