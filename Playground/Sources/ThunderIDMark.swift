// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

/// The ThunderID mark, drawn from its 207 x 257 source paths, with the top bar lightened for the
/// playground's dark background.
struct ThunderIDMark: View {
    var height: CGFloat = 26

    var body: some View {
        Canvas { context, size in
            let transform = CGAffineTransform(scaleX: size.width / 207, y: size.height / 257)
            context.fill(Self.topBar.applying(transform), with: .color(Color(hex: 0xE8F4FF)))
            context.fill(Self.leftBar.applying(transform), with: .color(Palette.primary))
            context.fill(Self.bolt.applying(transform), with: .color(Palette.primary))
        }
        .frame(width: height * 207 / 257, height: height)
        .accessibilityLabel("ThunderID")
    }

    private static let topBar = Path { path in
        path.move(to: CGPoint(x: 55.4763, y: 26.4391))
        path.addLine(to: CGPoint(x: 58.8866, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 26.4391))
        path.closeSubpath()
    }

    private static let leftBar = Path { path in
        path.move(to: CGPoint(x: 39.8438, y: 147.407))
        path.addLine(to: CGPoint(x: 49.5455, y: 72.2839))
        path.addLine(to: CGPoint(x: 0, y: 72.2839))
        path.addLine(to: CGPoint(x: 0, y: 256.743))
        path.addLine(to: CGPoint(x: 60.5602, y: 256.743))
        path.addLine(to: CGPoint(x: 80.048, y: 147.407))
        path.closeSubpath()
    }

    private static let bolt = Path { path in
        path.move(to: CGPoint(x: 192.42, y: 59.361))
        path.addCurve(
            to: CGPoint(x: 150.903, y: 15.3381),
            control1: CGPoint(x: 182.782, y: 40.2307),
            control2: CGPoint(x: 168.929, y: 25.5705)
        )
        path.addCurve(
            to: CGPoint(x: 133.703, y: 7.5208),
            control1: CGPoint(x: 145.501, y: 12.2662),
            control2: CGPoint(x: 139.761, y: 9.6605)
        )
        path.addLine(to: CGPoint(x: 115.401, y: 103.702))
        path.addLine(to: CGPoint(x: 159.757, y: 103.702))
        path.addLine(to: CGPoint(x: 76.2987, y: 256.743))
        path.addLine(to: CGPoint(x: 83.3735, y: 256.743))
        path.addCurve(
            to: CGPoint(x: 150.14, y: 241.236),
            control1: CGPoint(x: 109.449, y: 256.743),
            control2: CGPoint(x: 131.69, y: 251.574)
        )
        path.addCurve(
            to: CGPoint(x: 192.356, y: 196.959),
            control1: CGPoint(x: 168.569, y: 230.897),
            control2: CGPoint(x: 182.634, y: 216.131)
        )
        path.addCurve(
            to: CGPoint(x: 206.909, y: 128.043),
            control1: CGPoint(x: 202.058, y: 177.765),
            control2: CGPoint(x: 206.909, y: 154.8)
        )
        path.addCurve(
            to: CGPoint(x: 192.441, y: 59.3821),
            control1: CGPoint(x: 206.909, y: 101.286),
            control2: CGPoint(x: 202.079, y: 78.5123)
        )
        path.closeSubpath()
    }
}
