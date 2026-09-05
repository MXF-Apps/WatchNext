import Foundation

public struct WatchNextLogError: Codable, Hashable, Sendable {
    public let domain: String
    public let code: Int
    public let description: String
    public let failureReason: String?
    public let recoverySuggestion: String?

    public init(error: any Error) {
        let error = error as NSError
        domain = error.domain
        code = error.code
        description = error.localizedDescription
        failureReason = error.localizedFailureReason
        recoverySuggestion = error.localizedRecoverySuggestion
    }
}
