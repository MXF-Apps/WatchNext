public protocol SourceLoading: Sendable {
    func load(configuration: ServiceConfiguration) async throws -> SourceSnapshot
    func credentials() async throws -> [CredentialKey: String]
}
