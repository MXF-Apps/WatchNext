import Foundation

enum AppConfigurationError: LocalizedError {
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let service):
            String(localized: .settingsServerInvalidURLMessage(service: service))
        }
    }
}
