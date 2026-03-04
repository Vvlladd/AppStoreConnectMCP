import Foundation
import MCP

do {
    let configuration = try Configuration.fromEnvironment()
    let jwtGenerator = try JWTGenerator(configuration: configuration)
    let client = AppStoreConnectClient(jwtGenerator: jwtGenerator)
    let router = ToolRouter(client: client)

    let server = Server(
        name: "appstoreconnect",
        version: "1.0.0",
        capabilities: .init(tools: .init())
    )

    await server.withMethodHandler(ListTools.self) { _ in
        ListTools.Result(tools: ToolDefinitions.allTools)
    }

    await server.withMethodHandler(CallTool.self) { params in
        await router.route(params)
    }

    let transport = StdioTransport()
    try await server.start(transport: transport)
    await server.waitUntilCompleted()
} catch {
    FileHandle.standardError.write(Data("Fatal: \(error.localizedDescription)\n".utf8))
    exit(1)
}
