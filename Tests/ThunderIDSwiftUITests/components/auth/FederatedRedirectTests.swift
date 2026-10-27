// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import ThunderID
import XCTest
@testable import ThunderIDSwiftUI

@MainActor
final class FederatedRedirectTests: XCTestCase {
    private func decode(_ json: String) throws -> EmbeddedFlowResponse {
        try JSONDecoder().decode(EmbeddedFlowResponse.self, from: Data(json.utf8))
    }

    /// A federated registration step (the one that precedes the account-linking prompt) is followed.
    func testFollowsARegistrationRedirectionStep() throws {
        let response = try decode("""
        {"executionId": "f1", "flowStatus": "INCOMPLETE", "type": "REDIRECTION", "challengeToken": "ct1",
         "data": {"redirectURL": "https://accounts.example.com/authorize?state=s1"}}
        """)
        XCTAssertEqual(
            FederatedRedirect.redirectURL(in: response), "https://accounts.example.com/authorize?state=s1"
        )
    }

    func testSignUpStateKeepsTheLinkingPrompt() throws {
        let response = try decode("""
        {"executionId": "f1", "flowStatus": "INCOMPLETE", "type": "VIEW",
         "data": {"additionalData": {"linkingPromptDetails": "[]"},
                  "meta": {"components": [{"id": "kv", "type": "KEY_VALUE_LIST", "source": "linkingPromptDetails"}]}}}
        """)
        XCTAssertNil(FederatedRedirect.redirectURL(in: response))

        let state = SignUpState { _, _, _, _ in }
        state.update(from: response)
        XCTAssertEqual(state.components.first?.type, "KEY_VALUE_LIST")
        XCTAssertNotNil(state.additionalData["linkingPromptDetails"])
    }

    func testReturnsCodeAndStateFromACallbackEchoingTheRequestState() throws {
        let request = try XCTUnwrap(URL(string: "https://accounts.example.com/authorize?state=s1"))
        let callback = try XCTUnwrap(URL(string: "app://callback?code=abc&state=s1"))
        XCTAssertEqual(
            try FederatedRedirect.inputs(from: callback, redirectURL: request), ["code": "abc", "state": "s1"]
        )
    }

    func testRejectsACallbackWhenTheRequestCarriesNoState() throws {
        for raw in ["https://accounts.example.com/authorize", "https://accounts.example.com/authorize?state="] {
            let request = try XCTUnwrap(URL(string: raw))
            let callback = try XCTUnwrap(URL(string: "app://callback?code=abc&state="))
            XCTAssertThrowsError(try FederatedRedirect.inputs(from: callback, redirectURL: request)) { error in
                XCTAssertEqual((error as? ThunderIDError)?.code, .invalidGrant)
            }
        }
    }

    func testRejectsACallbackWithoutACode() throws {
        let request = try XCTUnwrap(URL(string: "https://accounts.example.com/authorize?state=s1"))
        let callback = try XCTUnwrap(URL(string: "app://callback?state=s1"))
        XCTAssertThrowsError(try FederatedRedirect.inputs(from: callback, redirectURL: request))
    }

    func testRejectsACallbackWhoseStateDoesNotMatchTheRequest() throws {
        let request = try XCTUnwrap(URL(string: "https://accounts.example.com/authorize?state=s1"))
        for raw in ["app://callback?code=abc&state=other", "app://callback?code=abc"] {
            let callback = try XCTUnwrap(URL(string: raw))
            XCTAssertThrowsError(try FederatedRedirect.inputs(from: callback, redirectURL: request)) { error in
                XCTAssertEqual((error as? ThunderIDError)?.code, .invalidGrant)
            }
        }
    }

    func testIgnoresARedirectionStepWithoutAURL() throws {
        let response = try decode("""
        {"executionId": "f1", "flowStatus": "INCOMPLETE", "type": "REDIRECTION", "data": {}}
        """)
        XCTAssertNil(FederatedRedirect.redirectURL(in: response))
    }

    func testDefinesTheSignUpFederatedErrorString() {
        XCTAssertNotEqual(ThunderIDI18n().resolve("signUp.federatedError"), "signUp.federatedError")
    }
}
