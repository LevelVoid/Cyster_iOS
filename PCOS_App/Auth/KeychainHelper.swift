import Foundation
import Security

// MARK: - KeychainKey

enum KeychainKey: String {
    case firebaseUID     = "com.team2.cyster.auth.firebaseUID"
    case firebaseIDToken = "com.team2.cyster.auth.idToken"
    case refreshToken    = "com.team2.cyster.auth.refreshToken"
}

// MARK: - KeychainHelper

enum KeychainHelper {

    // MARK: Save

    @discardableResult
    static func save(key: KeychainKey, value: String) -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String:   data
        ]
        SecItemDelete(query as CFDictionary)           // overwrite any existing item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: Load

    static func load(key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    // MARK: Delete

    @discardableResult
    static func delete(key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: Delete All Auth Tokens

    static func clearAllAuthTokens() {
        delete(key: .firebaseUID)
        delete(key: .firebaseIDToken)
        delete(key: .refreshToken)
    }
}
