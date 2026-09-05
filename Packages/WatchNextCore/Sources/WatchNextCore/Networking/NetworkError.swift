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
            "The service URL is invalid."
        case .invalidResponse:
            "The service returned an invalid response."
        case .unauthorized:
            "Authentication failed. Check the configured credentials."
        case .server(let statusCode):
            "The service returned HTTP \(statusCode)."
        case .decoding:
            "The service response was not understood. Check that the server version is supported."
        case .missingConfiguration(let field):
            "Configure \(field) before refreshing."
        }
    }
}
