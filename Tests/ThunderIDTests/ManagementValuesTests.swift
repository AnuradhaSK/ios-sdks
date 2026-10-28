// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

@testable import ThunderID
import XCTest

/// Gateways, server-level variables and secrets, and configuration versions, import and export.
final class ManagementValuesTests: XCTestCase {
    private let base = ManagementTestServer.baseUrl

    private func json(_ request: URLRequest) -> NSDictionary? {
        ManagementTestServer.json(request.httpBody).map { NSDictionary(dictionary: $0) }
    }

    func testGatewayOperations() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.gateways

        server.resource = #"[{"id":"g-1","name":"Edge"}]"#
        let gateways = try await api.list()
        server.resource = #"{"id":"g-1","name":"Edge","key":"k-once"}"#
        let registration = try await api.create(RegisterGatewayRequest(name: "Edge", baseUrl: "https://edge"))
        _ = try await api.get(id: "g-1")
        _ = try await api.update(id: "g-1", UpdateGatewayRequest(name: "Edge 2"))
        try await api.delete(id: "g-1")
        server.resource = #"{"gatewayId":"g-1","dryRun":true,"queued":false}"#
        let applied = try await api.applyConfiguration(id: "g-1", ApplyGatewayConfigurationRequest(version: "v3", dryRun: true))
        _ = try await api.revertConfiguration(id: "g-1")
        server.resource = #"{"summary":{"added":1},"changes":[{"change":"added","lines":[{"kind":"+","text":"x"}]}]}"#
        let diff = try await api.configurationDiff(id: "g-1")
        server.resource = #"{"gatewayId":"g-1","resources":[{"resourceType":"application","id":"a","resource":{}}]}"#
        _ = try await api.appliedConfiguration(id: "g-1")
        server.resource = #"{"appliedVersion":"v3","appliedBy":{"id":"u","name":"Ada"}}"#
        let version = try await api.appliedVersion(id: "g-1")

        XCTAssertEqual(gateways.first?.name, "Edge")
        XCTAssertEqual(registration.key, "k-once")
        XCTAssertEqual(registration.gateway.id, "g-1")
        XCTAssertEqual(applied.dryRun, true)
        XCTAssertEqual(diff.summary?.added, 1)
        XCTAssertEqual(version.appliedBy?.name, "Ada")
        XCTAssertEqual(server.calls, [
            "GET \(base)/gateways",
            "POST \(base)/gateways",
            "GET \(base)/gateways/g-1",
            "PUT \(base)/gateways/g-1",
            "DELETE \(base)/gateways/g-1",
            "POST \(base)/gateways/g-1/apply",
            "POST \(base)/gateways/g-1/revert",
            "GET \(base)/gateways/g-1/diff",
            "GET \(base)/gateways/g-1/applied-configuration",
            "GET \(base)/gateways/g-1/applied-version"
        ])
        XCTAssertEqual(json(server.requests[1]), ["name": "Edge", "baseUrl": "https://edge"])
        XCTAssertEqual(json(server.requests[5]), ["version": "v3", "dryRun": true])
        XCTAssertEqual(json(server.requests[6]), [:])
    }

    func testGatewayVariablesAndSecrets() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.gateways
        let variable = #"{"name":"HOST","value":"h"}"#
        let secret = #"{"name":"KEY","exists":true}"#

        server.resource = #"{"totalResults":0,"startIndex":1,"count":0,"variables":[]}"#
        _ = try await api.variables(id: "g-1", limit: 5, names: ["A", "B"])
        server.resource = variable
        _ = try await api.variable(id: "g-1", name: "HOST")
        _ = try await api.createVariable(id: "g-1", ValueEntryRequest(name: "HOST", value: "h"))
        _ = try await api.updateVariable(id: "g-1", name: "HOST", ValueEntryUpdateRequest(value: "h2"))
        try await api.deleteVariable(id: "g-1", name: "HOST")
        server.resource = #"{"totalResults":0,"startIndex":1,"count":0,"secrets":[]}"#
        _ = try await api.secrets(id: "g-1", filter: "x")
        server.resource = secret
        let fetched = try await api.secret(id: "g-1", name: "KEY")
        _ = try await api.createSecret(id: "g-1", ValueEntryRequest(name: "KEY", value: "s", description: "d"))
        _ = try await api.updateSecret(id: "g-1", name: "KEY", ValueEntryUpdateRequest(value: "s2"))
        try await api.deleteSecret(id: "g-1", name: "KEY")

        XCTAssertTrue(fetched.exists)
        XCTAssertEqual(server.calls, [
            "GET \(base)/gateways/g-1/variables?limit=5&names=A,B",
            "GET \(base)/gateways/g-1/variables/HOST",
            "POST \(base)/gateways/g-1/variables",
            "PUT \(base)/gateways/g-1/variables/HOST",
            "DELETE \(base)/gateways/g-1/variables/HOST",
            "GET \(base)/gateways/g-1/secrets?filter=x",
            "GET \(base)/gateways/g-1/secrets/KEY",
            "POST \(base)/gateways/g-1/secrets",
            "PUT \(base)/gateways/g-1/secrets/KEY",
            "DELETE \(base)/gateways/g-1/secrets/KEY"
        ])
        XCTAssertEqual(json(server.requests[7]), ["name": "KEY", "value": "s", "description": "d"])
        XCTAssertEqual(json(server.requests[8]), ["value": "s2"])
    }

    func testServerVariablesAndSecrets() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()

        server.resource = #"{"totalResults":0,"startIndex":1,"count":0,"variables":[]}"#
        _ = try await client.variables.list(limit: 1, offset: 2, names: ["A"], filter: "f")
        server.resource = #"{"name":"A","value":"1"}"#
        _ = try await client.variables.get(name: "A")
        _ = try await client.variables.create(ValueEntryRequest(name: "A", value: "1"))
        _ = try await client.variables.update(name: "A", ValueEntryUpdateRequest(value: "2", description: "d"))
        try await client.variables.delete(name: "A")
        server.resource = #"{"totalResults":0,"startIndex":1,"count":0,"secrets":[]}"#
        _ = try await client.secrets.list()
        server.resource = #"{"name":"S","exists":false}"#
        _ = try await client.secrets.get(name: "S")
        _ = try await client.secrets.create(ValueEntryRequest(name: "S", value: "v"))
        _ = try await client.secrets.update(name: "S", ValueEntryUpdateRequest(value: "w"))
        try await client.secrets.delete(name: "S")

        XCTAssertEqual(server.calls, [
            "GET \(base)/variables?limit=1&offset=2&names=A&filter=f",
            "GET \(base)/variables/A",
            "POST \(base)/variables",
            "PUT \(base)/variables/A",
            "DELETE \(base)/variables/A",
            "GET \(base)/secrets",
            "GET \(base)/secrets/S",
            "POST \(base)/secrets",
            "PUT \(base)/secrets/S",
            "DELETE \(base)/secrets/S"
        ])
        XCTAssertEqual(json(server.requests[3]), ["value": "2", "description": "d"])
    }

    func testConfigurationVersionsImportAndExport() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.configuration
        var export = ExportRequest()
        export.applications = ["*"]
        export.options = ExportOptions(includeDependencies: true)

        server.resource = #"[{"number":1,"version":"v1","current":true}]"#
        let versions = try await api.versions()
        server.resource = #"{"number":1,"version":"v1","createdBy":{"id":"u","name":"Ada"}}"#
        _ = try await api.version("v1")
        _ = try await api.createVersion(CaptureConfigurationVersionRequest(name: "Release", current: true))
        server.resource = #"{"resources":"kind: Application","environment_variables":"A=1"}"#
        let exported = try await api.exportConfiguration(export)
        server.resource = #"{"summary":{"totalDocuments":1,"imported":1,"failed":0,"importedAt":"t"},"#
            + #""results":[{"resourceType":"application","status":"success"}]}"#
        let imported = try await api.importConfiguration(
            ImportRequest(content: "kind: Application", variables: ["A": AnyCodable("1")], dryRun: true)
        )
        server.resource = #"{"resourceType":"application","resourceKey":"app","deletedFile":"app.yaml"}"#
        let deleted = try await api.deleteImportedConfiguration(
            DeleteImportedConfigurationRequest(resourceType: "application", resourceKey: "app")
        )

        XCTAssertEqual(versions.first?.current, true)
        XCTAssertEqual(exported.environmentVariables, "A=1")
        XCTAssertEqual(imported.summary.imported, 1)
        XCTAssertEqual(deleted.deletedFile, "app.yaml")
        XCTAssertEqual(server.calls, [
            "GET \(base)/configuration-versions",
            "GET \(base)/configuration-versions/v1",
            "POST \(base)/configuration-versions",
            "POST \(base)/export",
            "POST \(base)/import",
            "POST \(base)/import/delete"
        ])
        XCTAssertEqual(json(server.requests[2]), ["name": "Release", "current": true])
        XCTAssertEqual(json(server.requests[3]), ["applications": ["*"], "options": ["includeDependencies": true]])
        XCTAssertEqual(json(server.requests[4]), ["content": "kind: Application", "variables": ["A": "1"], "dryRun": true])
    }
}
