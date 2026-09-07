import Foundation
import Security

public struct KeychainError: LocalizedError, Sendable {
    public let status: OSStatus

    public init(status: OSStatus) {
        self.status = status
    }

    public var errorDescription: String? {
        SecCopyErrorMessageString(status, nil) as String? ?? String(localized: "security.keychain.error.message", defaultValue: "Keychain error \(status).", bundle: .module)
    }
}
