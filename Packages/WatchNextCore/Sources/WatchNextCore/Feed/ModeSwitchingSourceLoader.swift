/// Routes each refresh to the live servers or to the demo catalog, following
/// `ServiceConfiguration.demoMode`, so app and widget switch together.
public struct ModeSwitchingSourceLoader: SourceLoading {
    private let live: any SourceLoading
    private let demo: any SourceLoading

    public init(live: any SourceLoading, demo: any SourceLoading = DemoSourceLoader()) {
        self.live = live
        self.demo = demo
    }

    public func load(configuration: ServiceConfiguration) async throws -> SourceSnapshot {
        if configuration.demoMode {
            return try await demo.load(configuration: configuration)
        }
        return try await live.load(configuration: configuration)
    }

    /// Credentials only matter for artwork downloads from real servers; the demo
    /// catalog carries no artwork URLs, so live credentials are harmless there.
    public func credentials() async throws -> [CredentialKey: String] {
        try await live.credentials()
    }
}
