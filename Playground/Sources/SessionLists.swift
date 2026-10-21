// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct TokensList: View {
    let tokens: [TokenItem]
    @Binding var revealed: Set<String>
    let storageService: String

    var body: some View {
        VStack(spacing: 10) {
            if tokens.isEmpty {
                EmptyState(text: "No tokens. Sign in from Checks or the card above.")
            }
            ForEach(tokens) { token in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(token.name)
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Text(token.meta)
                            .font(.mono(11.5, weight: .medium))
                            .foregroundColor(Palette.text(0.5))
                    }
                    Text(shown(token))
                        .font(.mono(12))
                        .foregroundColor(Palette.code)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .textSelection(.enabled)
                    HStack(spacing: 8) {
                        ChipButton(label: revealed.contains(token.id) ? "Hide" : "Reveal") {
                            if revealed.contains(token.id) {
                                revealed.remove(token.id)
                            } else {
                                revealed.insert(token.id)
                            }
                        }
                        ChipButton(label: "Copy", systemImage: "doc.on.doc") { Clipboard.copy(token.value) }
                    }
                }
                .padding(14)
                .playgroundGroup()
            }
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lock")
                    .font(.system(size: 12))
                Text("Stored in the Keychain by KeychainStorageAdapter (service \(storageService), "
                    + "accessible when unlocked).")
                    .font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(Palette.text(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func shown(_ token: TokenItem) -> String {
        revealed.contains(token.id) ? token.value : String(token.value.prefix(12)) + String(repeating: "•", count: 23)
    }
}

struct ClaimsList: View {
    let claims: [(key: String, value: String)]
    let source: String

    var body: some View {
        VStack(spacing: 8) {
            if claims.isEmpty {
                EmptyState(text: "No claims. Sign in to decode the session's tokens.")
            } else {
                SectionLabel(text: source)
                VStack(spacing: 0) {
                    ForEach(claims, id: \.key) { claim in
                        HStack(alignment: .top, spacing: 16) {
                            Text(claim.key)
                                .font(.mono(12.5, weight: .medium))
                                .foregroundColor(Palette.accent)
                            Spacer(minLength: 0)
                            Text(claim.value)
                                .font(.mono(12.5))
                                .foregroundColor(Palette.text(0.8))
                                .multilineTextAlignment(.trailing)
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        if claim.key != claims.last?.key {
                            Divider().overlay(Palette.text(0.06))
                        }
                    }
                }
                .playgroundGroup()
            }
        }
    }
}

struct EventList: View {
    let entries: [LogEntry]

    var body: some View {
        if entries.isEmpty {
            EmptyState(text: "No events yet.")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(entries) { entry in
                    EventRow(entry: entry)
                    if entry.id != entries.last?.id {
                        Divider().overlay(Palette.text(0.06))
                    }
                }
            }
            .playgroundGroup()
        }
    }
}

struct EventRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(entry.name)
                    .font(.mono(12.5, weight: .medium))
                    .foregroundColor(color)
                Spacer()
                Text(entry.time)
                    .font(.mono(11.5))
                    .foregroundColor(Palette.text(0.4))
            }
            if !entry.detail.isEmpty {
                Text(entry.detail)
                    .font(.mono(11.5))
                    .foregroundColor(Palette.text(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var color: Color {
        switch entry.kind {
        case .success: return Palette.successText
        case .info: return Palette.link
        case .error: return Palette.dangerText
        }
    }
}

struct EmptyState: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(Palette.text(0.5))
            .frame(maxWidth: .infinity, minHeight: 80)
            .playgroundGroup()
    }
}
