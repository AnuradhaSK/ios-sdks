// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Management: server resources

public extension ThunderIDClient {
    /// Organization unit management operations. Throws until `initialize(config:)` has run.
    var organizationUnits: OrganizationUnitsAPI {
        get throws {
            OrganizationUnitsAPI(
                transport: try managementTransport("organization-units", override: \.organizationUnits)
            )
        }
    }

    /// Resource server, resource and action management operations. Throws until `initialize(config:)` has run.
    var resourceServers: ResourceServersAPI {
        get throws {
            ResourceServersAPI(transport: try managementTransport("resource-servers", override: \.resourceServers))
        }
    }

    /// Connection management operations. Throws until `initialize(config:)` has run.
    var connections: ConnectionsAPI {
        get throws {
            ConnectionsAPI(
                transport: try managementTransport("connections", override: \.connections, isSensitive: true)
            )
        }
    }

    /// Flow definition management operations. Throws until `initialize(config:)` has run.
    var flows: FlowsAPI {
        get throws { FlowsAPI(transport: try managementTransport("flows", override: \.flows)) }
    }

    /// Notification template management operations. Throws until `initialize(config:)` has run.
    var notificationTemplates: NotificationTemplatesAPI {
        get throws {
            NotificationTemplatesAPI(
                transport: try managementTransport("notification-templates", override: \.notificationTemplates)
            )
        }
    }

    /// Theme and layout management operations. Throws until `initialize(config:)` has run.
    var design: DesignAPI {
        get throws { DesignAPI(transport: try managementTransport("design", override: \.design)) }
    }

    /// Translation management operations. Throws until `initialize(config:)` has run.
    var translations: TranslationsAPI {
        get throws { TranslationsAPI(transport: try managementTransport("i18n", override: \.i18n)) }
    }

    /// Server configuration operations. Throws until `initialize(config:)` has run.
    var serverConfig: ServerConfigAPI {
        get throws { ServerConfigAPI(transport: try managementTransport("server-config", override: \.serverConfig)) }
    }

    /// Gateway management operations. Throws until `initialize(config:)` has run.
    var gateways: GatewaysAPI {
        get throws {
            GatewaysAPI(transport: try managementTransport("gateways", override: \.gateways, isSensitive: true))
        }
    }

    /// Server-level variable operations. Throws until `initialize(config:)` has run.
    var variables: VariablesAPI {
        get throws {
            VariablesAPI(transport: try managementTransport("variables", override: \.variables, isSensitive: true))
        }
    }

    /// Server-level secret operations. Throws until `initialize(config:)` has run.
    var secrets: SecretsAPI {
        get throws {
            SecretsAPI(transport: try managementTransport("secrets", override: \.secrets, isSensitive: true))
        }
    }

    /// Configuration versions, import and export. Throws until `initialize(config:)` has run.
    var configuration: ConfigurationAPI {
        get throws {
            ConfigurationAPI(
                versionsTransport: try managementTransport("configuration-versions", override: \.configurationVersions),
                importTransport: try managementTransport("import", override: \.import, isSensitive: true),
                exportTransport: try managementTransport("export", override: \.export, isSensitive: true)
            )
        }
    }
}
