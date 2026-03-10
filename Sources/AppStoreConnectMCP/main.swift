import Foundation
import Logging
import MCP

LoggingSystem.bootstrap { StderrLogHandler(label: $0) }

let logger = Logger(label: "appstoreconnect.main")

do {
    let (orgConfigs, defaultOrg) = try Configuration.allFromEnvironment()
    logger.info("Configuring \(orgConfigs.count) organization(s), default: \(defaultOrg)")

    var organizations: [OrganizationRegistry.Organization] = []
    for (name, config) in orgConfigs {
        let jwtGenerator = try JWTGenerator(
            configuration: config,
            logger: Logger(label: "appstoreconnect.jwt.\(name)")
        )
        let client = AppStoreConnectClient(
            jwtGenerator: jwtGenerator,
            logger: Logger(label: "appstoreconnect.http.\(name)")
        )
        organizations.append(OrganizationRegistry.Organization(
            name: name,
            client: client,
            authMode: config.authMode
        ))
    }

    let registry = OrganizationRegistry(organizations: organizations, defaultOrgName: defaultOrg)
    let router = ToolRouter(registry: registry)

    let server = Server(
        name: "appstoreconnect",
        version: "1.1.0",
        capabilities: .init(logging: .init(), tools: .init())
    )

    await server.withMethodHandler(ListTools.self) { _ in
        ListTools.Result(tools: ToolDefinitions.allTools)
    }

    await server.withMethodHandler(CallTool.self) { params in
        await router.route(params)
    }

    let transport = StdioTransport()
    try await server.start(transport: transport)
    logger.info("Server started")
    await server.waitUntilCompleted()
} catch {
    logger.critical("Fatal: \(error.localizedDescription)")
    FileHandle.standardError.write(Data("Fatal: \(error.localizedDescription)\n".utf8))
    exit(1)
}
