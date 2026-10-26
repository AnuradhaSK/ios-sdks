// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderID

extension FlowComponent {
    /// The font a `TEXT` component's heading variant renders with, or `nil` when it renders as body text.
    /// Each level keeps its own step on the type scale. `HEADING_5` and `HEADING_6` stay body text,
    /// since the step templates use `HEADING_6` as a subtitle.
    var headingFont: Font? {
        switch variant {
        case "HEADING_1": return .title2
        case "HEADING_2": return .title3
        case "HEADING_3": return .headline
        case "HEADING_4": return .subheadline
        default: return nil
        }
    }
}
