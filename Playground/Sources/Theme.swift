// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Colors from the playground design: dark navy canvas, blue primary, cyan accent.
enum Palette {
    static let background = Color(hex: 0x050B18)
    static let sheet = Color(hex: 0x0A1428)
    static let tabBar = Color(hex: 0x060D1C)
    static let primary = Color(hex: 0x3688FF)
    static let primaryDeep = Color(hex: 0x2060C8)
    static let accent = Color(hex: 0x8BF9FA)
    static let link = Color(hex: 0x9CC4FF)
    static let code = Color(hex: 0xCFE3FF)
    static let success = Color(hex: 0x34D399)
    static let successText = Color(hex: 0x6EE7B7)
    static let danger = Color(hex: 0xEF4444)
    static let dangerText = Color(hex: 0xFCA5A5)
    static let warning = Color(hex: 0xF59E0B)
    static let warningText = Color(hex: 0xFCD34D)
    static let idle = Color(hex: 0x94A3B8)

    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDeep],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let cardGradient = LinearGradient(
        colors: [Color(hex: 0x09142C), Color(hex: 0x040A18)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let avatarGradient = LinearGradient(
        colors: [Color(hex: 0x22D3EE), Color(hex: 0x0E7490)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func text(_ opacity: Double) -> Color { Color.white.opacity(opacity) }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension Font {
    /// JetBrains Mono in the design; the system monospaced face stands in on device.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// The gradient summary/user card (16pt radius).
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Palette.cardGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Palette.text(0.09), lineWidth: 1)
            )
    }
}

/// The bordered list container used for check rows, claims and events.
struct GroupModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Palette.text(0.025))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Palette.text(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func playgroundCard() -> some View { modifier(CardModifier()) }
    func playgroundGroup() -> some View { modifier(GroupModifier()) }
}

/// Segmented control in the design's style: a tinted track with the selected segment highlighted.
struct SegmentedPicker<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.value) { option in
                let isOn = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    Text(option.label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isOn ? .white : Palette.text(0.6))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(isOn ? Palette.primary.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Palette.text(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Small secondary button used for Reveal, Copy and similar inline actions.
struct ChipButton: View {
    let label: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(label)
                    .font(.system(size: 12.5))
            }
            .foregroundColor(Palette.text(0.85))
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(Palette.text(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.9)
            .foregroundColor(Palette.text(0.45))
            .padding(.horizontal, 4)
            .padding(.top, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Copies text to the system pasteboard on iOS, and to the general pasteboard on macOS.
enum Clipboard {
    static func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}
