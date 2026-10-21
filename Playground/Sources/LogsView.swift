// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct LogsView: View {
    enum Filter: Hashable {
        case all
        case errors
    }

    @EnvironmentObject private var log: EventLog
    @State private var filter: Filter = .all

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Logs")
                        .font(.system(size: 26))
                        .tracking(-0.5)
                    Text("\(log.entries.count) SDK events")
                        .font(.mono(11.5, weight: .medium))
                        .foregroundColor(Palette.accent)
                }
                Spacer()
                ChipButton(label: "Clear", systemImage: "trash") { log.clear() }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
            ScrollView {
                VStack(spacing: 14) {
                    SegmentedPicker(options: [(Filter.all, "All"), (Filter.errors, "Errors")], selection: $filter)
                    EventList(entries: entries)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
    }

    private var entries: [LogEntry] {
        filter == .all ? log.entries : log.entries.filter { $0.kind == .error }
    }
}
