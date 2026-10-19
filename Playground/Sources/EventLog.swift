// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import Foundation

struct LogEntry: Identifiable {
    enum Kind {
        case info
        case success
        case error
    }

    let id = UUID()
    let date: Date
    let name: String
    let detail: String
    let kind: Kind

    var time: String { Self.formatter.string(from: date) }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

/// Log of what the playground asked the SDK to do and what came back. The iOS SDK has no event
/// emitter, so entries are recorded around each SDK call, from the storage adapter the SDK writes
/// tokens through, and from changes to the published `ThunderIDState`.
final class EventLog: ObservableObject {
    private static let limit = 300

    @Published private(set) var entries: [LogEntry] = []

    func record(_ name: String, _ detail: String = "", kind: LogEntry.Kind = .info) {
        let entry = LogEntry(date: Date(), name: name, detail: detail, kind: kind)
        if Thread.isMainThread {
            append(entry)
        } else {
            DispatchQueue.main.async { self.append(entry) }
        }
    }

    func clear() {
        entries.removeAll()
    }

    private func append(_ entry: LogEntry) {
        entries.insert(entry, at: 0)
        if entries.count > Self.limit {
            entries.removeLast(entries.count - Self.limit)
        }
    }
}
