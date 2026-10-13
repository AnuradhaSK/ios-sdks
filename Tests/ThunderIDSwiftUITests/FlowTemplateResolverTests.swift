// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

@testable import ThunderID
import XCTest
@testable import ThunderIDSwiftUI

final class FlowTemplateResolverTests: XCTestCase {
    func testResolvesTranslationTemplate() {
        let meta: [String: Any] = [
            "i18n": [
                "translations": [
                    "signin": [
                        "forms.credentials.fields.username.label": "Username"
                    ]
                ]
            ]
        ]
        let resolver = FlowTemplateResolver(meta: meta)
        XCTAssertEqual(
            resolver.resolve("{{ t(signin:forms.credentials.fields.username.label) }}"),
            "Username"
        )
    }

    func testResolvesMetaDotPathTemplate() {
        let meta: [String: Any] = [
            "application": [
                "forgot_password_url": "https://example.com/reset"
            ]
        ]
        let resolver = FlowTemplateResolver(meta: meta)
        XCTAssertEqual(
            resolver.resolve("{{meta(application.forgot_password_url)}}"),
            "https://example.com/reset"
        )
    }

    func testLeavesUnrecognisedExpressionUnchanged() {
        let resolver = FlowTemplateResolver(meta: [:])
        XCTAssertEqual(resolver.resolve("{{ unknown(foo) }}"), "{{ unknown(foo) }}")
    }

    func testReturnsPlainTextUnchangedWhenNoTemplate() {
        let resolver = FlowTemplateResolver(meta: [:])
        XCTAssertEqual(resolver.resolve("Plain text"), "Plain text")
    }

    func testResolvesMultipleTemplatesInOneString() {
        let meta: [String: Any] = [
            "i18n": [
                "translations": [
                    "signin": [
                        "forms.credentials.links.forgot_password.prefix": "Forgot",
                        "forms.credentials.links.forgot_password.label": "password?"
                    ]
                ]
            ]
        ]
        let resolver = FlowTemplateResolver(meta: meta)
        let text = "{{ t(signin:forms.credentials.links.forgot_password.prefix) }} " +
            "{{ t(signin:forms.credentials.links.forgot_password.label) }}"
        XCTAssertEqual(resolver.resolve(text), "Forgot password?")
    }

    func testReturnsEmptyStringForMissingTranslationKey() {
        let resolver = FlowTemplateResolver(meta: [:])
        XCTAssertEqual(resolver.resolve("{{ t(signin:missing.key) }}"), "")
    }

    func testTranslatesAFlowErrorKeyWithItsParams() {
        let resolver = FlowTemplateResolver(meta: [
            "i18n": [
                "translations": [
                    "errors": ["user.exists": "{{param(name)}} existe déjà"],
                    "system": ["flow.invalid": "Flux invalide"]
                ]
            ]
        ])

        XCTAssertEqual(
            resolver.translate(
                FlowErrorText(key: "errors.user.exists", defaultValue: "alice already exists", params: ["name": "alice"])
            ),
            "alice existe déjà"
        )
        // A key with no translation of its own is retried under the system namespace.
        XCTAssertEqual(
            resolver.translate(FlowErrorText(key: "flow.invalid", defaultValue: "Invalid flow", params: nil)),
            "Flux invalide"
        )
        // A placeholder left without a param, or a key with no translation, leaves the caller to its fallback.
        XCTAssertNil(resolver.translate(FlowErrorText(key: "errors.user.exists", defaultValue: "x", params: nil)))
        XCTAssertNil(resolver.translate(FlowErrorText(key: "errors.missing", defaultValue: "Missing", params: nil)))
        XCTAssertNil(resolver.translate(FlowErrorText(key: nil, defaultValue: "No key", params: nil)))
        XCTAssertNil(resolver.translate(nil))
    }

    func testSubstitutesFlowErrorParamsInOnePass() {
        let resolver = FlowTemplateResolver(meta: [
            "i18n": ["translations": ["errors": ["pair": "{{param(first)}} / {{param(second)}}"]]]
        ])

        // A value is inserted as written, never read as a placeholder or a regex template.
        XCTAssertEqual(
            resolver.translate(
                FlowErrorText(key: "errors.pair", defaultValue: "x", params: ["first": "$1 \\0", "second": "b"])
            ),
            "$1 \\0 / b"
        )
        // A value holding a placeholder stays a placeholder, so the caller falls back.
        XCTAssertNil(
            resolver.translate(
                FlowErrorText(
                    key: "errors.pair", defaultValue: "x", params: ["first": "{{param(second)}}", "second": "b"]
                )
            )
        )
    }
}
