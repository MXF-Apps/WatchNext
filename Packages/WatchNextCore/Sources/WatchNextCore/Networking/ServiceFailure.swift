import Foundation

/// An error from one specific server, so callers can say which one failed
/// and send the user to the right place to fix it.
public struct ServiceFailure: LocalizedError, Sendable {
    public let service: ServiceKind
    public let underlying: any Error

    public init(service: ServiceKind, underlying: any Error) {
        self.service = service
        self.underlying = underlying
    }

    public var errorDescription: String? {
        String(
            localized: "service.failure.message",
            defaultValue: "\(service.name): \(underlying.localizedDescription)",
            bundle: .module
        )
    }

    /// Runs `work` and attributes anything it throws to `service`.
    public static func attributing<T: Sendable>(
        _ service: ServiceKind,
        _ work: @Sendable () async throws -> T
    ) async throws -> T {
        do {
            return try await work()
        } catch let failure as ServiceFailure {
            throw failure
        } catch {
            throw ServiceFailure(service: service, underlying: error)
        }
    }
}
