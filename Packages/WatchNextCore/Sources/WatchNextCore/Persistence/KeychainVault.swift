import Foundation
import Security
import WatchNextLogging

public actor KeychainVault: SecretVault {
    private let service: String
    private let accessGroup: String?
    private let logger: WatchNextLogger

    public init(
        service: String = "WatchNext.Credentials",
        accessGroup: String? = Bundle.main.object(
            forInfoDictionaryKey: WatchNextConstants.keychainAccessGroupInfoKey
        ) as? String,
        logger: WatchNextLogger = .shared
    ) {
        self.service = service
        self.accessGroup = accessGroup
        self.logger = logger
    }

    public func create(_ value: String, for account: String) throws {
        var item = baseQuery(for: account)
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else {
            let error = KeychainError(status: status)
            logger.error("Could not create credential \(account).", error: error, category: "Keychain")
            throw error
        }
        logger.debug("Created credential \(account).", category: "Keychain")
    }

    public func read(account: String) throws -> String? {
        var query = baseQuery(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            logger.debug("Credential \(account) was not found.", category: "Keychain")
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            let error = KeychainError(status: status)
            logger.error("Could not read credential \(account).", error: error, category: "Keychain")
            throw error
        }
        logger.debug("Read credential \(account).", category: "Keychain")
        return String(data: data, encoding: .utf8)
    }

    public func update(_ value: String, for account: String) throws {
        let attributes = [kSecValueData as String: Data(value.utf8)]
        let status = SecItemUpdate(baseQuery(for: account) as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else {
            let error = KeychainError(status: status)
            logger.error("Could not update credential \(account).", error: error, category: "Keychain")
            throw error
        }
        logger.debug("Updated credential \(account).", category: "Keychain")
    }

    public func delete(account: String) throws {
        let status = SecItemDelete(baseQuery(for: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            let error = KeychainError(status: status)
            logger.error("Could not delete credential \(account).", error: error, category: "Keychain")
            throw error
        }
        logger.debug("Deleted credential \(account).", category: "Keychain")
    }

    private func baseQuery(for account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let accessGroup, accessGroup.contains("$(") == false {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}
