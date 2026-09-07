import Foundation

public enum NetworkError: LocalizedError, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(statusCode: Int)
    case decoding(String)
    case missingConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            String(localized: "network.error.invalidURL.message", defaultValue: "The service URL is invalid.", bundle: .module)
        case .invalidResponse:
            String(localized: "network.error.invalidResponse.message", defaultValue: "The service returned an invalid response.", bundle: .module)
        case .unauthorized:
            String(localized: "network.error.unauthorized.message", defaultValue: "Authentication failed. Check the configured credentials.", bundle: .module)
        case .server(let statusCode):
            String(localized: "network.error.server.message", defaultValue: "The service returned HTTP \(statusCode).", bundle: .module)
        case .decoding:
            String(localized: "network.error.decoding.message", defaultValue: "The service response was not understood. Check that the server version is supported.", bundle: .module)
        case .missingConfiguration(let field):
            String(localized: "network.error.configuration.message", defaultValue: "Configure \(field) before refreshing.", bundle: .module)
        }
    }
}
