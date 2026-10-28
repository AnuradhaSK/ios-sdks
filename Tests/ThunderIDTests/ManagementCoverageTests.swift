// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

@testable import ThunderID
import XCTest

/// Organization units, resource servers, users and applications by path, sharing and overlay rules,
/// the account lifecycle operations, and the endpoint overrides of the new collections.
final class ManagementCoverageTests: XCTestCase {
    private let base = ManagementTestServer.baseUrl
    private let unit = #"{"id":"ou-1","handle":"eng","name":"Engineering","parent":null,"themeId":"t-1"}"#

    private func json(_ request: URLRequest) -> NSDictionary? {
        ManagementTestServer.json(request.httpBody).map { NSDictionary(dictionary: $0) }
    }

    // MARK: - Organization units

    func testOrganizationUnitOperationsByIdAndPath() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.organizationUnits
        let page = #"{"totalResults":0,"organizationUnits":[]}"#

        server.resource = page
        _ = try await api.list(limit: 5, offset: 10, filter: #"handle eq "eng""#)
        server.resource = unit
        let byId = try await api.get(id: "ou-1")
        _ = try await api.get(path: "/eng/front end/")
        _ = try await api.create(OrganizationUnitRequest(handle: "eng", name: "Engineering", parent: nil))
        _ = try await api.update(id: "ou-1", OrganizationUnitRequest(handle: "eng", name: "Eng", parent: "root"))
        _ = try await api.update(path: "eng/web", OrganizationUnitPathRequest(handle: "web", name: "Web"))
        try await api.delete(id: "ou-1")
        try await api.delete(path: "eng/web")

        XCTAssertEqual(byId.themeId, "t-1")
        XCTAssertNil(byId.parent)
        XCTAssertEqual(server.calls, [
            "GET \(base)/organization-units?limit=5&offset=10&filter=handle%20eq%20%22eng%22",
            "GET \(base)/organization-units/ou-1",
            "GET \(base)/organization-units/tree/eng/front%20end",
            "POST \(base)/organization-units",
            "PUT \(base)/organization-units/ou-1",
            "PUT \(base)/organization-units/tree/eng/web",
            "DELETE \(base)/organization-units/ou-1",
            "DELETE \(base)/organization-units/tree/eng/web"
        ])
        XCTAssertEqual(json(server.requests[3]), ["handle": "eng", "name": "Engineering", "parent": NSNull()])
        XCTAssertEqual(json(server.requests[4]), ["handle": "eng", "name": "Eng", "parent": "root"])
        XCTAssertEqual(json(server.requests[5]), ["handle": "web", "name": "Web"])
    }

    func testOrganizationUnitRelatedListsByIdAndPath() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.organizationUnits

        server.resource = #"{"organizationUnits":[]}"#
        _ = try await api.children(.id("ou-1"), limit: 2)
        _ = try await api.children(.path("a/b?c"), offset: 4, filter: "x")
        server.resource = #"{"users":[{"id":"u-1","display":"Ada","isOwned":false}]}"#
        let users = try await api.users(.path("a/b"), limit: 1)
        _ = try await api.users(.id("ou-1"))
        server.resource = #"{"groups":[]}"#
        _ = try await api.groups(.path("a"), limit: 3, offset: 6)
        server.resource = #"{"roles":[]}"#
        _ = try await api.roles(.id("ou-1"))

        XCTAssertEqual(users.users.first?.isOwned, false)
        XCTAssertEqual(server.calls, [
            "GET \(base)/organization-units/ou-1/ous?limit=2",
            "GET \(base)/organization-units/tree/a/b%3Fc/ous?offset=4&filter=x",
            "GET \(base)/organization-units/tree/a/b/users?limit=1&include=display",
            "GET \(base)/organization-units/ou-1/users?include=display",
            "GET \(base)/organization-units/tree/a/groups?limit=3&offset=6",
            "GET \(base)/organization-units/ou-1/roles"
        ])
    }

    func testOrganizationUnitPathsMustNameEverySegment() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.organizationUnits

        await assertThrowsThunderIDError(.invalidInput) { _ = try await api.get(path: "") }
        await assertThrowsThunderIDError(.invalidInput) { _ = try await api.get(path: "a//b") }
        await assertThrowsThunderIDError(.invalidInput) { try await api.delete(path: " / ") }
        await assertThrowsThunderIDError(.invalidInput) { _ = try await api.get(id: " ") }
        XCTAssertTrue(server.requests.isEmpty)
        XCTAssertEqual(try ManagementPath.tree("/a/b c/"), ["a", "b c"])
    }

    // MARK: - Users and applications

    func testUsersByPath() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()

        server.resource = #"{"totalResults":0,"startIndex":1,"count":0,"users":[]}"#
        _ = try await client.users.list(path: "eng/web", limit: 10, offset: 0)
        server.resource = #"{"id":"u-1","ouId":"ou-1","type":"person"}"#
        _ = try await client.users.create(
            path: "eng",
            CreateUserByPathRequest(type: "person", attributes: ["email": AnyCodable("a@b.c")])
        )

        XCTAssertEqual(server.calls, [
            "GET \(base)/users/tree/eng/web?limit=10&offset=0&include=display",
            "POST \(base)/users/tree/eng"
        ])
        XCTAssertEqual(json(server.requests[1]), ["type": "person", "attributes": ["email": "a@b.c"]])
    }

    func testSharingPoliciesAndOverlayRulesForUsersAndApplications() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let policy = #"{"id":"p-1","version":2,"childUnits":{"mode":"selected","units":[{"ouId":"o","reach":"unit"}]}}"#
        let create = SharingPolicyRequest(childUnits: .selected([SharingChildUnit(ouId: "o", reach: "subtree")]))
        let update = SharingPolicyUpdateRequest(version: 2, childUnits: .all(excluding: ["x"]))

        for (collection, id) in [("users", "u-1"), ("applications", "app-1")] {
            server.resource = #"{"policies":[\#(policy)]}"#
            let list = collection == "users"
                ? try await client.users.sharingPolicies(id: id, limit: 5)
                : try await client.applications.sharingPolicies(id: id, limit: 5)
            server.resource = policy
            if collection == "users" {
                _ = try await client.users.sharingPolicy(id: id, policyId: "p-1")
                _ = try await client.users.createSharingPolicy(id: id, create)
                _ = try await client.users.updateSharingPolicy(id: id, policyId: "p-1", update)
                try await client.users.deleteSharingPolicy(id: id, policyId: "p-1")
            } else {
                _ = try await client.applications.sharingPolicy(id: id, policyId: "p-1")
                _ = try await client.applications.createSharingPolicy(id: id, create)
                _ = try await client.applications.updateSharingPolicy(id: id, policyId: "p-1", update)
                try await client.applications.deleteSharingPolicy(id: id, policyId: "p-1")
            }
            server.resource = #"{"ouId":"o","visible":true,"rules":{"email":{"editable":false,"value":["a"]}}}"#
            let overlay = collection == "users"
                ? try await client.users.overlayRules(id: id, ouId: "o")
                : try await client.applications.overlayRules(id: id, ouId: "o")

            XCTAssertEqual(list.policies.first?.childUnits?.units?.first?.reach, "unit")
            XCTAssertEqual(overlay.rules?["email"]?.editable, false)
        }

        let expected = [("users", "u-1"), ("applications", "app-1")].flatMap { collection, id in [
            "GET \(base)/\(collection)/\(id)/sharing-policies?limit=5",
            "GET \(base)/\(collection)/\(id)/sharing-policies/p-1",
            "POST \(base)/\(collection)/\(id)/sharing-policies",
            "PUT \(base)/\(collection)/\(id)/sharing-policies/p-1",
            "DELETE \(base)/\(collection)/\(id)/sharing-policies/p-1",
            "GET \(base)/\(collection)/\(id)/overlay-rules?ouId=o"
        ] }
        XCTAssertEqual(server.calls, expected)
        XCTAssertEqual(
            json(server.requests[2]),
            ["childUnits": ["mode": "selected", "units": [["ouId": "o", "reach": "subtree"]]]]
        )
        XCTAssertEqual(json(server.requests[3]), ["version": 2, "childUnits": ["mode": "all", "excludedOuIds": ["x"]]])
    }

    // MARK: - Account lifecycle

    private typealias Lifecycle = (ThunderIDClient, String, String?) async throws -> AccountLifecycleResult

    private let lifecycleOperations: [(key: String, run: Lifecycle)] = [
        ("userSuspendFlow", { try await $0.users.suspend(id: $1, operatorNote: $2) }),
        ("userUnsuspendFlow", { try await $0.users.unsuspend(id: $1, operatorNote: $2) }),
        ("userUnlockFlow", { try await $0.users.unlock(id: $1, operatorNote: $2) }),
        ("agentSuspendFlow", { try await $0.agents.suspend(id: $1, operatorNote: $2) }),
        ("agentUnsuspendFlow", { try await $0.agents.unsuspend(id: $1, operatorNote: $2) }),
        ("agentUnlockFlow", { try await $0.agents.unlock(id: $1, operatorNote: $2) }),
        ("applicationSuspendFlow", { try await $0.applications.suspend(id: $1, operatorNote: $2) }),
        ("applicationUnsuspendFlow", { try await $0.applications.unsuspend(id: $1, operatorNote: $2) })
    ]

    func testLifecycleOperationsRunTheirFlowWithSubjectAndNote() async throws {
        for operation in lifecycleOperations {
            let server = ManagementTestServer()
            server.config = #"{"\#(operation.key)":{"defaultHandle":"h"}}"#
            server.flows = [("h", "flow-1")]
            server.execution = #"{"flowStatus":"COMPLETE","data":{"additionalData":{"emailSent":"true"}}}"#
            let client = try await server.makeClient()

            let result = try await operation.run(client, "id-1", "policy breach")

            XCTAssertEqual(result.emailSent, true, operation.key)
            XCTAssertEqual(server.executions.count, 1, operation.key)
            XCTAssertEqual(server.executions.first?["flowId"] as? String, "flow-1")
            XCTAssertEqual(
                server.executions.first?["inputs"] as? [String: String],
                ["subject": "id-1", "operatorNote": "policy breach"],
                operation.key
            )
            XCTAssertFalse(server.calls.contains { $0.hasPrefix("DELETE") || $0.hasPrefix("PUT") })
        }
    }

    func testLifecycleReportsWhetherTheEmailWentOut() async throws {
        for (data, expected) in [(#"{"emailSent":"false"}"#, false), ("{}", nil as Bool?)] {
            let server = ManagementTestServer()
            server.config = #"{"userSuspendFlow":{"defaultHandle":"h"}}"#
            server.flows = [("h", "flow-1")]
            server.execution = #"{"flowStatus":"COMPLETE","data":{"additionalData":\#(data)}}"#
            let client = try await server.makeClient()

            let result = try await client.users.suspend(id: "u-1")

            XCTAssertEqual(result.emailSent, expected)
            XCTAssertEqual(server.executions.first?["inputs"] as? [String: String], ["subject": "u-1"])
        }
    }

    func testLifecycleFailsWhenNoFlowIsConfigured() async throws {
        for operation in lifecycleOperations {
            let server = ManagementTestServer()
            let client = try await server.makeClient()

            let error = await assertThrowsThunderIDError(.administrationFlowNotConfigured) {
                _ = try await operation.run(client, "id-1", nil)
            }

            XCTAssertEqual(error?.isAdministrationFlowError, true)
            XCTAssertTrue(server.executions.isEmpty, operation.key)
            XCTAssertEqual(server.calls, ["GET \(base)/server-config/flow"], operation.key)
        }
    }

    // MARK: - Agent types

    func testAgentTypeCreateAndDelete() async throws {
        let server = ManagementTestServer()
        server.resource = #"{"id":"a-1","handle":"bot","displayName":"Bot","ouId":"ou-1","schema":{}}"#
        let client = try await server.makeClient()

        _ = try await client.agentTypes.create(
            CreateAgentTypeRequest(handle: "bot", displayName: "Bot", ouId: "ou-1", schema: [:])
        )
        try await client.agentTypes.delete(id: "a-1")

        XCTAssertEqual(server.calls, ["POST \(base)/agent-types", "DELETE \(base)/agent-types/a-1"])
        XCTAssertEqual(json(server.requests[0]), ["handle": "bot", "displayName": "Bot", "ouId": "ou-1", "schema": [:]])
    }

    // MARK: - Endpoint overrides

    func testNewCollectionsFollowTheirEndpointOverrides() async throws {
        let server = ManagementTestServer()
        let host = "https://mgmt.example.com"
        let endpoints = ThunderIDEndpoints(
            configurationVersions: "\(host)/cv",
            connections: "\(host)/conn",
            design: "\(host)/dsg",
            export: "\(host)/exp",
            flows: "\(host)/fl",
            gateways: "\(host)/gw",
            i18n: "\(host)/tr",
            import: "\(host)/imp",
            notificationTemplates: "\(host)/nt",
            organizationUnits: "\(host)/ous",
            resourceServers: "\(host)/rs/",
            secrets: "\(host)/sec",
            serverConfig: "\(host)/sc",
            variables: "\(host)/var"
        )
        let client = try await server.makeClient(endpoints: endpoints)
        let attempts: [() async throws -> Void] = [
            { _ = try await client.organizationUnits.get(id: "x") },
            { _ = try await client.resourceServers.get(id: "x") },
            { _ = try await client.connections.meta() },
            { _ = try await client.flows.get(id: "x") },
            { _ = try await client.notificationTemplates.get(channel: .sms, id: "x") },
            { _ = try await client.design.theme(id: "x") },
            { _ = try await client.translations.languages() },
            { _ = try await client.serverConfig.get(name: "x") },
            { _ = try await client.gateways.get(id: "x") },
            { _ = try await client.variables.get(name: "x") },
            { _ = try await client.secrets.get(name: "x") },
            { _ = try await client.configuration.version("1") },
            { _ = try await client.configuration.importConfiguration(ImportRequest()) },
            { _ = try await client.configuration.exportConfiguration(ExportRequest()) }
        ]
        for attempt in attempts {
            // The canned body does not decode as each type; only the URL matters here.
            _ = try? await attempt()
        }

        XCTAssertEqual(server.calls.map { $0.components(separatedBy: " ")[1] }, [
            "\(host)/ous/x", "\(host)/rs/x", "\(host)/conn/meta", "\(host)/fl/x", "\(host)/nt/sms/templates/x",
            "\(host)/dsg/themes/x", "\(host)/tr/languages", "\(host)/sc/x", "\(host)/gw/x", "\(host)/var/x",
            "\(host)/sec/x", "\(host)/cv/1", "\(host)/imp", "\(host)/exp"
        ])
    }

    func testCredentialCarryingCollectionsAreNeverLogged() async throws {
        let client = try await ManagementTestServer().makeClient()

        XCTAssertTrue(try client.connections.transport.isSensitive)
        XCTAssertTrue(try client.gateways.transport.isSensitive)
        XCTAssertTrue(try client.variables.transport.isSensitive)
        XCTAssertTrue(try client.secrets.transport.isSensitive)
        XCTAssertTrue(try client.configuration.importTransport.isSensitive)
        XCTAssertTrue(try client.configuration.exportTransport.isSensitive)
        XCTAssertFalse(try client.organizationUnits.transport.isSensitive)
    }
}
