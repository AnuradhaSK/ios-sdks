// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

@testable import ThunderID
import XCTest

/// Resource servers, connections, flows, notification templates, design, translations, server
/// configuration, gateways, variables and secrets, and configuration versions, import and export.
final class ManagementResourcesTests: XCTestCase {
    private let base = ManagementTestServer.baseUrl
    private let action = #"{"id":"ac-1","name":"Read","handle":"read","permission":"orders:read"}"#

    private func json(_ request: URLRequest) -> NSDictionary? {
        ManagementTestServer.json(request.httpBody).map { NSDictionary(dictionary: $0) }
    }

    // MARK: - Resource servers

    func testResourceServersResourcesAndActions() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.resourceServers
        let resourceServer = #"{"id":"rs-1","name":"Orders","identifier":"orders","type":"API","ouId":"o","delimiter":":"}"#
        let resource = #"{"id":"r-1","name":"Order","handle":"order","permission":"orders:order"}"#

        server.resource = #"{"resourceServers":[]}"#
        _ = try await api.list(limit: 1, offset: 2)
        server.resource = resourceServer
        _ = try await api.get(id: "rs-1")
        _ = try await api.create(CreateResourceServerRequest(name: "Orders", identifier: "orders", ouId: "o"))
        _ = try await api.update(id: "rs-1", UpdateResourceServerRequest(name: "Orders", ouId: "o"))
        try await api.delete(id: "rs-1")
        server.resource = #"{"resources":[]}"#
        _ = try await api.resources(resourceServerId: "rs-1", parentId: "r-0", limit: 5)
        server.resource = resource
        _ = try await api.resource(resourceServerId: "rs-1", resourceId: "r-1")
        _ = try await api.createResource(resourceServerId: "rs-1", CreateServerResourceRequest(name: "Order", handle: "order"))
        _ = try await api.updateResource(resourceServerId: "rs-1", resourceId: "r-1", UpdateNamedItemRequest(name: "O"))
        try await api.deleteResource(resourceServerId: "rs-1", resourceId: "r-1")

        XCTAssertEqual(server.calls, [
            "GET \(base)/resource-servers?limit=1&offset=2",
            "GET \(base)/resource-servers/rs-1",
            "POST \(base)/resource-servers",
            "PUT \(base)/resource-servers/rs-1",
            "DELETE \(base)/resource-servers/rs-1",
            "GET \(base)/resource-servers/rs-1/resources?parentId=r-0&limit=5",
            "GET \(base)/resource-servers/rs-1/resources/r-1",
            "POST \(base)/resource-servers/rs-1/resources",
            "PUT \(base)/resource-servers/rs-1/resources/r-1",
            "DELETE \(base)/resource-servers/rs-1/resources/r-1"
        ])
        XCTAssertEqual(json(server.requests[2]), ["name": "Orders", "identifier": "orders", "ouId": "o"])
        XCTAssertEqual(json(server.requests[8]), ["name": "O"])
    }

    func testActionsOnTheServerOrOnAResource() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.resourceServers

        server.resource = #"{"actions":[]}"#
        _ = try await api.actions(resourceServerId: "rs-1", kind: "tool")
        _ = try await api.actions(resourceServerId: "rs-1", resourceId: "r-1", limit: 2)
        server.resource = action
        _ = try await api.action(resourceServerId: "rs-1", actionId: "ac-1")
        _ = try await api.action(resourceServerId: "rs-1", resourceId: "r-1", actionId: "ac-1")
        _ = try await api.createAction(resourceServerId: "rs-1", CreateResourceActionRequest(name: "Read", handle: "read"))
        _ = try await api.createAction(
            resourceServerId: "rs-1",
            resourceId: "r-1",
            CreateResourceActionRequest(name: "Read", handle: "read", kind: "resource")
        )
        _ = try await api.updateAction(resourceServerId: "rs-1", actionId: "ac-1", UpdateNamedItemRequest(description: "d"))
        _ = try await api.updateAction(
            resourceServerId: "rs-1",
            resourceId: "r-1",
            actionId: "ac-1",
            UpdateNamedItemRequest(name: "R")
        )
        try await api.deleteAction(resourceServerId: "rs-1", actionId: "ac-1")
        try await api.deleteAction(resourceServerId: "rs-1", resourceId: "r-1", actionId: "ac-1")

        XCTAssertEqual(server.calls, [
            "GET \(base)/resource-servers/rs-1/actions?kind=tool",
            "GET \(base)/resource-servers/rs-1/resources/r-1/actions?limit=2",
            "GET \(base)/resource-servers/rs-1/actions/ac-1",
            "GET \(base)/resource-servers/rs-1/resources/r-1/actions/ac-1",
            "POST \(base)/resource-servers/rs-1/actions",
            "POST \(base)/resource-servers/rs-1/resources/r-1/actions",
            "PUT \(base)/resource-servers/rs-1/actions/ac-1",
            "PUT \(base)/resource-servers/rs-1/resources/r-1/actions/ac-1",
            "DELETE \(base)/resource-servers/rs-1/actions/ac-1",
            "DELETE \(base)/resource-servers/rs-1/resources/r-1/actions/ac-1"
        ])
        XCTAssertEqual(json(server.requests[5]), ["name": "Read", "handle": "read", "kind": "resource"])
    }

    func testDeleteActionRunsTheActionDeletionFlowInFlowMode() async throws {
        let server = ManagementTestServer()
        server.config = #"{"actionDeletionFlow":{"defaultHandle":"delete-action"}}"#
        server.flows = [("delete-action", "flow-9")]
        let client = try await server.makeClient()

        try await client.resourceServers.deleteAction(
            resourceServerId: "rs-1",
            resourceId: "r-1",
            actionId: "ac-1",
            administrationMode: .flow
        )
        try await client.resourceServers.deleteAction(resourceServerId: "rs-1", actionId: "ac-2", administrationMode: .flow)

        XCTAssertEqual(server.executions.map { $0["inputs"] as? [String: String] }, [
            ["targetActionId": "ac-1", "targetResourceServerId": "rs-1", "targetResourceId": "r-1"],
            ["targetActionId": "ac-2", "targetResourceServerId": "rs-1"]
        ])
        XCTAssertFalse(server.calls.contains { $0.hasPrefix("DELETE") })
    }

    func testDeleteActionFallsBackToTheAPIWithoutAFlow() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()

        try await client.resourceServers.deleteAction(resourceServerId: "rs-1", actionId: "ac-1", administrationMode: .flow)

        XCTAssertEqual(server.calls, [
            "GET \(base)/server-config/flow",
            "DELETE \(base)/resource-servers/rs-1/actions/ac-1"
        ])
        XCTAssertTrue(server.executions.isEmpty)
    }

    // MARK: - Connections

    func testConnectionOperations() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.connections
        let google = #"{"id":"c-1","name":"Google","type":"google","clientId":"cid","scopes":["openid"]}"#
        let request = ConnectionRequest(
            name: "Google",
            settings: ["clientId": AnyCodable("cid"), "redirectUri": AnyCodable("https://app/cb")]
        )

        server.resource = #"{"totalResults":1,"startIndex":1,"count":1,"connections":"#
            + #"[{"id":"c-1","name":"Google","type":"google","categories":["identity-provider"]}]}"#
        let all = try await api.list(category: "identity-provider", limit: 10)
        server.resource = #"[{"id":"c-1","name":"Google"}]"#
        let ofType = try await api.list(type: .google)
        server.resource = google
        let connection = try await api.get(type: .google, id: "c-1")
        _ = try await api.create(type: .emailSmtp, request)
        _ = try await api.update(type: .smsGateway, id: "c-2", request)
        try await api.delete(type: .authzenPdp, id: "c-3")
        server.resource = #"{"count":0,"usages":[]}"#
        _ = try await api.usages(type: .oidc, id: "c-1")
        server.resource = #"{"vendors":[{"vendor":"http","authentication":{"methods":[{"type":"basic"}]}}]}"#
        let meta = try await api.meta(vendor: .http)

        XCTAssertEqual(all.connections.first?.categories, ["identity-provider"])
        XCTAssertEqual(ofType.first?.id, "c-1")
        XCTAssertEqual(connection.settings["clientId"]?.value as? String, "cid")
        XCTAssertNil(connection.settings["name"])
        XCTAssertEqual(meta.vendors?.first?.authentication?.methods?.first?.type, "basic")
        XCTAssertEqual(server.calls, [
            "GET \(base)/connections?category=identity-provider&limit=10",
            "GET \(base)/connections/google",
            "GET \(base)/connections/google/c-1",
            "POST \(base)/connections/email-smtp",
            "PUT \(base)/connections/sms-gateway/c-2",
            "DELETE \(base)/connections/authzen-pdp/c-3",
            "GET \(base)/connections/oidc/c-1/usages",
            "GET \(base)/connections/meta?vendor=http"
        ])
        XCTAssertEqual(json(server.requests[3]), ["name": "Google", "clientId": "cid", "redirectUri": "https://app/cb"])
        let reencoded = try XCTUnwrap(ManagementTestServer.json(try JSONEncoder().encode(connection)))
        XCTAssertEqual(NSDictionary(dictionary: reencoded), [
            "id": "c-1", "name": "Google", "type": "google", "clientId": "cid", "scopes": ["openid"]
        ])
    }

    // MARK: - Flows

    func testFlowOperationsKeepTheWholeGraph() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.flows
        let node = #"{"id":"n-1","type":"PROMPT","meta":{"components":[{"id":"c","type":"TEXT","extra":1}]},"next":"n-2"}"#
        let flow = #"{"id":"f-1","name":"Login","handle":"login","flowType":"AUTHENTICATION","activeVersion":2,"#
            + #""isReadOnly":false,"nodes":[\#(node)]}"#

        _ = try await api.list(flowType: "REGISTRATION", limit: 5)
        server.resource = flow
        let fetched = try await api.get(id: "f-1")
        _ = try await api.create(FlowDefinitionRequest(name: "Login", handle: "login", flowType: "AUTHENTICATION", nodes: fetched.nodes))
        _ = try await api.update(id: "f-1", FlowDefinitionRequest(name: "L", handle: "login", flowType: "AUTHENTICATION", nodes: []))
        try await api.delete(id: "f-1")
        server.resource = #"{"totalVersions":1,"versions":[{"version":1,"createdAt":"t","isActive":true}]}"#
        let versions = try await api.versions(id: "f-1")
        server.resource = #"{"id":"f-1","name":"Login","handle":"login","flowType":"AUTHENTICATION","version":1,"#
            + #""isActive":true,"nodes":[]}"#
        _ = try await api.version(id: "f-1", version: 1)
        server.resource = flow
        _ = try await api.restoreVersion(id: "f-1", version: 1)
        server.resource = #"{"usages":[{"resourceType":"application","id":"a","displayName":"A","behaviorOnDelete":"fallback"}]}"#
        let usages = try await api.usages(id: "f-1")

        XCTAssertEqual(versions.versions.first?.isActive, true)
        XCTAssertEqual(usages.usages?.first?.behaviorOnDelete, "fallback")
        XCTAssertEqual(server.calls, [
            "GET \(base)/flows?flowType=REGISTRATION&limit=5",
            "GET \(base)/flows/f-1",
            "POST \(base)/flows",
            "PUT \(base)/flows/f-1",
            "DELETE \(base)/flows/f-1",
            "GET \(base)/flows/f-1/versions",
            "GET \(base)/flows/f-1/versions/1",
            "POST \(base)/flows/f-1/restore",
            "GET \(base)/flows/f-1/usages"
        ])
        let sentNode = (ManagementTestServer.json(server.requests[2].httpBody)?["nodes"] as? [[String: Any]])?.first
        XCTAssertEqual(
            NSDictionary(dictionary: try XCTUnwrap(sentNode)),
            NSDictionary(dictionary: try XCTUnwrap(ManagementTestServer.json(Data(node.utf8))))
        )
        XCTAssertEqual(json(server.requests[7]), ["version": 1])
    }

    // MARK: - Notification templates and design

    func testNotificationTemplateOperations() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.notificationTemplates
        let template = #"{"id":"t-1","ouId":"o","handle":"otp","displayName":"OTP","content":{"body":"{{code}}"}}"#

        server.resource = #"{"templates":[]}"#
        _ = try await api.list(channel: .sms, limit: 2)
        server.resource = template
        _ = try await api.get(channel: .email, id: "t-1")
        _ = try await api.create(
            channel: .email,
            CreateNotificationTemplateRequest(
                handle: "otp",
                ouId: "o",
                displayName: "OTP",
                content: NotificationTemplateContent(subject: "Code", body: "{{code}}"),
                design: NotificationTemplateDesign(colorScheme: "dark")
            )
        )
        _ = try await api.update(
            channel: .sms,
            id: "t-1",
            UpdateNotificationTemplateRequest(displayName: "OTP", content: NotificationTemplateContent(body: "b"))
        )
        try await api.delete(channel: .sms, id: "t-1")

        XCTAssertEqual(server.calls, [
            "GET \(base)/notification-templates/sms/templates?limit=2",
            "GET \(base)/notification-templates/email/templates/t-1",
            "POST \(base)/notification-templates/email/templates",
            "PUT \(base)/notification-templates/sms/templates/t-1",
            "DELETE \(base)/notification-templates/sms/templates/t-1"
        ])
        XCTAssertEqual(json(server.requests[2]), [
            "handle": "otp", "ouId": "o", "displayName": "OTP",
            "content": ["subject": "Code", "body": "{{code}}"], "design": ["colorScheme": "dark"]
        ])
    }

    func testDesignOperations() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.design
        let theme = ThemeRequest(handle: "dark", displayName: "Dark", theme: ["primary": AnyCodable("#000")])
        let layout = LayoutRequest(handle: "split", displayName: "Split", layout: ["columns": AnyCodable(2)])

        server.resource = #"{"themes":[]}"#
        _ = try await api.themes(limit: 1)
        server.resource = ##"{"id":"t-1","theme":{"primary":"#000"}}"##
        _ = try await api.theme(id: "t-1")
        _ = try await api.createTheme(theme)
        _ = try await api.updateTheme(id: "t-1", theme)
        try await api.deleteTheme(id: "t-1")
        server.resource = #"{"usages":[]}"#
        _ = try await api.themeUsages(id: "t-1", offset: 3)
        server.resource = #"{"layouts":[]}"#
        _ = try await api.layouts(offset: 1)
        server.resource = #"{"id":"l-1"}"#
        _ = try await api.layout(id: "l-1")
        _ = try await api.createLayout(layout)
        _ = try await api.updateLayout(id: "l-1", layout)
        try await api.deleteLayout(id: "l-1")
        server.resource = #"{"usages":[]}"#
        _ = try await api.layoutUsages(id: "l-1")
        server.resource = #"{"theme":{"a":1},"layout":{}}"#
        let resolved = try await api.resolve(type: .application, id: "app-1")

        XCTAssertEqual(resolved.theme?["a"]?.value as? Int, 1)
        XCTAssertEqual(server.calls, [
            "GET \(base)/design/themes?limit=1",
            "GET \(base)/design/themes/t-1",
            "POST \(base)/design/themes",
            "PUT \(base)/design/themes/t-1",
            "DELETE \(base)/design/themes/t-1",
            "GET \(base)/design/themes/t-1/usages?offset=3",
            "GET \(base)/design/layouts?offset=1",
            "GET \(base)/design/layouts/l-1",
            "POST \(base)/design/layouts",
            "PUT \(base)/design/layouts/l-1",
            "DELETE \(base)/design/layouts/l-1",
            "GET \(base)/design/layouts/l-1/usages",
            "GET \(base)/design/resolve?type=APP&id=app-1"
        ])
        XCTAssertEqual(json(server.requests[2]), ["handle": "dark", "displayName": "Dark", "theme": ["primary": "#000"]])
    }

    // MARK: - Translations and server configuration

    func testTranslationOperations() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()
        let api = try client.translations
        let all = #"{"language":"fr-FR","translations":{"signin":{"title":"Connexion"}}}"#
        let one = #"{"language":"fr-FR","namespace":"signin","key":"title","value":"Connexion"}"#

        server.resource = #"{"languages":["en-US","fr-FR"]}"#
        let languages = try await api.languages()
        server.resource = all
        let resolved = try await api.resolveTranslations(language: "fr-FR", namespace: "signin")
        _ = try await api.setTranslations(language: "fr-FR", ["signin": ["title": "Connexion"]])
        try await api.deleteTranslations(language: "fr-FR")
        server.resource = one
        _ = try await api.resolveTranslation(language: "fr-FR", namespace: "signin", key: "title")
        _ = try await api.setTranslation(language: "fr-FR", namespace: "signin", key: "title", value: "Connexion")
        try await api.deleteTranslation(language: "fr-FR", namespace: "signin", key: "title")

        XCTAssertEqual(languages.languages, ["en-US", "fr-FR"])
        XCTAssertEqual(resolved.translations["signin"]?["title"], "Connexion")
        let path = "\(base)/i18n/languages/fr-FR/translations"
        XCTAssertEqual(server.calls, [
            "GET \(base)/i18n/languages",
            "GET \(path)/resolve?namespace=signin",
            "POST \(path)",
            "DELETE \(path)",
            "GET \(path)/ns/signin/keys/title/resolve",
            "POST \(path)/ns/signin/keys/title",
            "DELETE \(path)/ns/signin/keys/title"
        ])
        XCTAssertEqual(json(server.requests[2]), ["translations": ["signin": ["title": "Connexion"]]])
        XCTAssertEqual(json(server.requests[5]), ["value": "Connexion"])
    }

    func testServerConfigOperations() async throws {
        let server = ManagementTestServer()
        let client = try await server.makeClient()

        server.resource = #"["flow","accountAccess"]"#
        let names = try await client.serverConfig.names()
        server.resource = #"{"readOnly":{},"writable":{"user":{}},"merged":{"user":{}}}"#
        let layers = try await client.serverConfig.get(name: "accountAccess")
        _ = try await client.serverConfig.update(name: "accountAccess", ["user": AnyCodable(["recordLastLogin": AnyCodable(true)])])

        XCTAssertEqual(names, ["flow", "accountAccess"])
        XCTAssertNotNil(layers.merged?["user"])
        XCTAssertEqual(server.calls, [
            "GET \(base)/server-config",
            "GET \(base)/server-config/accountAccess",
            "PUT \(base)/server-config/accountAccess"
        ])
        XCTAssertEqual(json(server.requests[2]), ["user": ["recordLastLogin": true]])
    }
}
