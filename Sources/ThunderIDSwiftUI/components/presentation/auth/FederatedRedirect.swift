// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import Foundation
import ThunderID

/// The flow-execution `REDIRECTION` step, shared by the sign-in and sign-up loops: opens the
/// federated provider in a browser session and hands back the flow inputs from its callback
/// (`code`, plus `state` so the server can verify it too), which the caller resubmits with the
/// step's `flowId`/`challengeToken`.
@MainActor
enum FederatedRedirect {
    /// The redirect could not be started (malformed `redirectURL` or no `afterSignInUrl` scheme
    /// to capture the callback on).
    struct StartError: Error {}

    /// The `redirectURL` of a `REDIRECTION` step, or nil when `response` is not one.
    static func redirectURL(in response: EmbeddedFlowResponse) -> String? {
        response.type == "REDIRECTION" ? response.data?.redirectURL : nil
    }

    /// Throws `FederatedAuthSession.CancelledError` when the user dismisses the browser sheet.
    static func callbackInputs(
        redirectURL: String, client: ThunderIDClient, session: FederatedAuthSession
    ) async throws -> [String: String] {
        guard let url = URL(string: redirectURL),
              let afterSignInUrl = try? client.getConfiguration().afterSignInUrl,
              let scheme = URLComponents(string: afterSignInUrl)?.scheme else {
            throw StartError()
        }
        let callbackURL = try await session.authenticate(url: url, callbackURLScheme: scheme)
        return try inputs(from: callbackURL, redirectURL: url)
    }

    /// The `code` and `state` of the provider's callback. Any app can open the callback scheme, so
    /// a callback that does not echo the `state` of the request it answers is rejected, and so is
    /// any callback to a request that carried no `state` to check against.
    static func inputs(from callbackURL: URL, redirectURL: URL) throws -> [String: String] {
        guard let code = queryValue("code", in: callbackURL) else {
            throw ThunderIDError(code: .invalidGrant, message: "Authorization code missing from callback URL")
        }
        guard let expectedState = queryValue("state", in: redirectURL), !expectedState.isEmpty,
              queryValue("state", in: callbackURL) == expectedState else {
            throw ThunderIDError(code: .invalidGrant, message: "Callback state does not match the federated request")
        }
        return ["code": code, "state": expectedState]
    }

    private static func queryValue(_ name: String, in url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == name }?.value
    }
}
