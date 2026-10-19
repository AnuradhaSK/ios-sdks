// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import Foundation
import ThunderID

/// Keychain-backed `StorageAdapter` handed to the SDK through `ThunderIDConfig.storage`. It reports
/// every operation to the event log (key names only, never values) and lets the session inspector
/// read back the token set the SDK persisted.
final class PlaygroundStorage: StorageAdapter {
    /// Keys the SDK's token store writes. The SDK has no public accessor for the ID token, refresh
    /// token or expiry, so the inspector reads them through this adapter instead.
    enum Key {
        static let accessToken = "thunder.access_token"
        static let refreshToken = "thunder.refresh_token"
        static let idToken = "thunder.id_token"
        static let tokenExpiry = "thunder.token_expiry"
    }

    let service: String
    private let keychain: KeychainStorageAdapter
    private let log: EventLog

    init(vendor: String, log: EventLog) {
        service = "dev.\(vendor).playground"
        keychain = KeychainStorageAdapter(service: service)
        self.log = log
    }

    func store(key: String, value: String) throws {
        do {
            try keychain.store(key: key, value: value)
            log.record("storage:write", key)
        } catch {
            log.record("storage:write", "\(key) failed: \(error.localizedDescription)", kind: .error)
            throw error
        }
    }

    func retrieve(key: String) -> String? {
        keychain.retrieve(key: key)
    }

    func delete(key: String) {
        keychain.delete(key: key)
        log.record("storage:delete", key)
    }

    func clear() {
        keychain.clear()
        log.record("storage:clear", service)
    }

    /// When the stored access token expires, from the expiry the SDK saved next to it.
    var accessTokenExpiry: Date? {
        retrieve(key: Key.tokenExpiry)
            .flatMap(TimeInterval.init)
            .map(Date.init(timeIntervalSince1970:))
    }
}
