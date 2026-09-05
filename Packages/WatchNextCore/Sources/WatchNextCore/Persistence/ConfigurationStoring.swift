public protocol ConfigurationStoring: Sendable {
    func load() async -> ServiceConfiguration
    func save(_ configuration: ServiceConfiguration) async throws
}
