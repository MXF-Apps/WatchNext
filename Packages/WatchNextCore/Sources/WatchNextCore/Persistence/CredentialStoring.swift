public protocol CredentialStoring: Sendable {
    func value(for key: CredentialKey) async throws -> String?
    func set(_ value: String?, for key: CredentialKey) async throws
}
