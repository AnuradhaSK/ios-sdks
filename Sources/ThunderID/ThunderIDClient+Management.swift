// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Management

public extension ThunderIDClient {
    /// Application management operations. Throws until `initialize(config:)` has run.
    var applications: ApplicationsAPI {
        get throws { ApplicationsAPI(transport: try managementTransport("applications", override: \.applications)) }
    }

    /// User management operations. Throws until `initialize(config:)` has run.
    var users: UsersAPI {
        get throws {
            UsersAPI(
                transport: try managementTransport("users", override: \.users),
                typesTransport: try managementTransport("user-types", override: \.userTypes)
            )
        }
    }

    /// User type management operations. Throws until `initialize(config:)` has run.
    var userTypes: UserTypesAPI {
        get throws { UserTypesAPI(transport: try managementTransport("user-types", override: \.userTypes)) }
    }

    /// Group management operations. Throws until `initialize(config:)` has run.
    var groups: GroupsAPI {
        get throws { GroupsAPI(transport: try managementTransport("groups", override: \.groups)) }
    }

    /// Role management operations. Throws until `initialize(config:)` has run.
    var roles: RolesAPI {
        get throws { RolesAPI(transport: try managementTransport("roles", override: \.roles)) }
    }

    /// Agent management operations. Throws until `initialize(config:)` has run.
    var agents: AgentsAPI {
        get throws {
            AgentsAPI(
                transport: try managementTransport("agents", override: \.agents),
                typesTransport: try managementTransport("agent-types", override: \.agentTypes)
            )
        }
    }

    /// Agent type management operations. Throws until `initialize(config:)` has run.
    var agentTypes: AgentTypesAPI {
        get throws { AgentTypesAPI(transport: try managementTransport("agent-types", override: \.agentTypes)) }
    }

    /// The administration flows the server configures for state-changing operations. They always run
    /// against `baseUrl`. Throws until `initialize(config:)` has run.
    var administrationFlows: AdministrationFlowsAPI {
        get throws { AdministrationFlowsAPI(transport: try managementTransport("flows", override: nil)) }
    }

    /// The permissions the signed-in user's access token carries, read from its `scopes` or `scope`
    /// claim. Use it with ``ThunderIDPermissions/has(_:_:)`` to decide what to show; the server still
    /// authorizes every request. Returns an empty list when no one is signed in.
    func getGrantedPermissions() async -> [String] {
        guard let token = try? await getAccessToken() else { return [] }
        return ThunderIDPermissions.fromAccessToken(token)
    }
}

extension ThunderIDClient {
    /// The transport for one collection. Set `isSensitive` for a collection whose bodies can carry a
    /// credential, so they are never logged.
    func managementTransport(
        _ collection: String,
        override: KeyPath<ThunderIDEndpoints, String?>?,
        isSensitive: Bool = false
    ) throws -> ManagementTransport {
        let config = try requireInitialized()
        guard let httpClient else {
            throw ThunderIDError(code: .sdkNotInitialized, message: "Call initialize() before using the SDK")
        }
        return ManagementTransport(
            httpClient: httpClient,
            baseUrl: config.baseUrl,
            collectionUrl: override.flatMap { config.endpoints[keyPath: $0] } ?? "\(config.baseUrl)/\(collection)",
            fetcher: config.http.fetcher,
            isSensitive: isSensitive
        )
    }
}
