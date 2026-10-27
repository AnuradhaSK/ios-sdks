// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderID
import ThunderIDSwiftUI

extension ExplorerCatalog {
    static func customApplicationDetails(applicationId: String) -> ComponentSpec {
        ComponentSpec(
            id: "customApplicationDetails",
            name: "ApplicationDetails → card",
            group: "Custom rendering",
            defaults: ["source": "sample", "applicationId": applicationId],
            controls: [
                StoryControl(name: "source", kind: .options(["sample", "live"])),
                StoryControl(name: "applicationId", kind: .text)
            ],
            stories: [
                Story(id: "sample", name: "Sample", preset: ["source": "sample"]),
                Story(id: "live", name: "Live", preset: ["source": "live"])
            ],
            isTall: true
        ) { values in
            let head = values.isLive
                ? "ApplicationDetails(applicationId: \(quote(values.text("applicationId"))), secretRegenerable: true)"
                : "BaseApplicationDetails(application: application, onRegenerateSecret: { /* rotate */ })"
            return """
            \(head) { details in
                VStack(alignment: .leading, spacing: 12) {
                    Text(details.application?.name ?? "").font(.title2.bold())
                    if let secret = details.clientSecret {
                        Text(secret).font(.body.monospaced()).textSelection(.enabled)
                        Button("I copied it") { details.onSecretDone?() }
                    } else if let rotate = details.onRegenerateSecret {
                        Button("Rotate secret") { confirming = true }
                            .confirmationDialog("Rotate?", isPresented: $confirming) {
                                Button("Rotate", role: .destructive, action: rotate)
                            }
                    }
                }
            }
            """
        }
    }
}

/// The application details state drawn as a card, confirming the rotation itself as the custom
/// render must.
struct CustomApplicationDetailsStory: View {
    @EnvironmentObject private var state: ThunderIDState
    let values: PropValues
    let onEvent: (String) -> Void
    @State private var secret: String?

    var body: some View {
        if values.isLive {
            if values.text("applicationId").isEmpty {
                PreviewHint(text: "Set applicationId, or run the Applications check to find one on the server.")
            } else {
                ApplicationDetails(applicationId: values.text("applicationId"), secretRegenerable: true) {
                    ApplicationCard(details: $0)
                }
            }
        } else {
            BaseApplicationDetails(
                application: AdminSamples.application,
                clientSecret: secret,
                onSecretDone: { secret = nil },
                onRegenerateSecret: {
                    secret = "sample-secret-shown-once"
                    onEvent("onRegenerateSecret")
                },
                content: { ApplicationCard(details: $0) }
            )
        }
    }
}

private struct ApplicationCard: View {
    let details: ApplicationDetailsState
    @State private var isConfirming = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if details.isLoading && details.application == nil {
                ProgressView()
            } else if let application = details.application {
                Text(application.name).font(.system(size: 22, weight: .semibold))
                Text(application.description ?? application.type ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                if let error = details.error {
                    Text(error).foregroundColor(.red)
                }
                secretRow
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.text(0.05)))
    }

    @ViewBuilder private var secretRow: some View {
        if let secret = details.clientSecret {
            Text(secret)
                .font(.system(size: 14, design: .monospaced))
                .textSelection(.enabled)
            Button("I copied it") { details.onSecretDone?() }
        } else if let rotate = details.onRegenerateSecret {
            Button("Rotate secret") { isConfirming = true }
                .disabled(details.isRegeneratingSecret)
                .confirmationDialog("Rotate the client secret?", isPresented: $isConfirming) {
                    Button("Rotate", role: .destructive, action: rotate)
                }
        }
    }
}
