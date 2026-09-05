import Foundation

enum AppConfigurationError: LocalizedError {
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let service):
            "Enter a valid HTTP or HTTPS URL for \(service)."
        }
    }
}
