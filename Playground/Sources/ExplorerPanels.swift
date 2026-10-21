// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

/// Live prop editors for the selected component.
struct ControlsPanel: View {
    let controls: [StoryControl]
    @Binding var values: PropValues

    var body: some View {
        VStack(spacing: 0) {
            if controls.isEmpty {
                Text("This component takes callbacks only. Interact with the preview to fire them.")
                    .font(.system(size: 13))
                    .foregroundColor(Palette.text(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            }
            ForEach(controls, id: \.name) { control in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(control.name)
                            .font(.mono(13, weight: .medium))
                            .foregroundColor(Palette.accent)
                        Spacer()
                        if control.kind == .bool {
                            Toggle(control.name, isOn: flag(control.name))
                                .labelsHidden()
                                .tint(Palette.primary)
                        }
                    }
                    editor(for: control)
                }
                .padding(.vertical, 12)
                Divider().overlay(Palette.text(0.06))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 16)
    }

    @ViewBuilder private func editor(for control: StoryControl) -> some View {
        switch control.kind {
        case .text:
            TextField(control.name, text: text(control.name))
                .font(.system(size: 15))
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Palette.text(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Palette.text(0.12), lineWidth: 1)
                )
        case .options(let options):
            SegmentedPicker(options: options.map { ($0, $0) }, selection: text(control.name))
        case .bool:
            EmptyView()
        }
    }

    private func text(_ name: String) -> Binding<String> {
        Binding(
            get: { values[name] ?? "" },
            set: { values[name] = $0 }
        )
    }

    private func flag(_ name: String) -> Binding<Bool> {
        Binding(
            get: { values[name] == "true" },
            set: { values[name] = $0 ? "true" : "false" }
        )
    }
}

/// SwiftUI snippet for the current props, with a copy button.
struct CodePanel: View {
    let code: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SwiftUI")
                    .font(.mono(11.5, weight: .medium))
                    .foregroundColor(Palette.text(0.5))
                Spacer()
                ChipButton(label: copied ? "Copied" : "Copy", systemImage: "doc.on.doc") {
                    Clipboard.copy(code)
                    copied = true
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.mono(12.5))
                    .foregroundColor(Palette.code)
                    .lineSpacing(5)
                    .fixedSize()
                    .textSelection(.enabled)
                    .padding(14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Palette.text(0.08), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 16)
        .onChange(of: code) { _ in copied = false }
    }
}
