// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

@testable import ThunderID
import XCTest

final class ServerErrorTests: XCTestCase {
    private func failure(_ body: String, status: Int) async throws -> ThunderIDError? {
        let server = ManagementTestServer()
        server.resource = body
        server.resourceStatus = status
        let client = try await server.makeClient()
        do {
            try await client.users.delete(id: "u-1")
        } catch let error as ThunderIDError {
            return error
        }
        XCTFail("Expected the request to fail")
        return nil
    }

    func testKeepsTheServersErrorEnvelopeWithItsCodeAndParams() async throws {
        let error = try await failure("""
        {"code": "USR-1027",
         "message": {"key": "error.user.in_use", "defaultValue": "User cannot be deleted"},
         "description": {"defaultValue": "Agents depend on it", "params": {"dependencies": "agents"}}}
        """, status: 409)

        // The SDK's own code is unchanged; the envelope rides alongside it.
        XCTAssertEqual(error?.code, .userAlreadyExists)
        XCTAssertEqual(error?.serverError, ServerError(
            code: "USR-1027",
            message: ServerErrorMessage(key: "error.user.in_use", defaultValue: "User cannot be deleted"),
            description: ServerErrorMessage(defaultValue: "Agents depend on it", params: ["dependencies": "agents"])
        ))
    }

    func testReadsAPlainStringDescription() async throws {
        let error = try await failure(
            #"{"code": "SSE-5000", "message": "Internal error", "description": "Try again later"}"#,
            status: 500
        )

        XCTAssertEqual(error?.code, .serverError)
        XCTAssertEqual(error?.serverError?.code, "SSE-5000")
        XCTAssertEqual(error?.serverError?.message?.defaultValue, "Internal error")
        XCTAssertEqual(error?.serverError?.description?.defaultValue, "Try again later")
    }

    func testHasNoServerErrorWhenTheBodyIsNotAnEnvelope() async throws {
        let notJson = try await failure("Bad gateway", status: 502)
        let otherJson = try await failure(#"{"foo": 1}"#, status: 500)
        let empty = try await failure("", status: 404)

        XCTAssertNil(notJson?.serverError)
        XCTAssertNil(otherJson?.serverError)
        XCTAssertEqual(empty?.code, .notFound)
        XCTAssertNil(empty?.serverError)
    }

    func testABadRequestKeepsItsCodeAndCarriesTheEnvelope() async throws {
        let error = try await failure(
            #"{"code": "USR-1001", "message": {"defaultValue": "Invalid user"}, "description": 42}"#,
            status: 400
        )

        XCTAssertEqual(error?.code, .invalidInput)
        XCTAssertEqual(error?.serverError?.code, "USR-1001")
        XCTAssertNil(error?.serverError?.description)
    }
}
