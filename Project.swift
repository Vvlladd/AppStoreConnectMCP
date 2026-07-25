import ProjectDescription

let mcpVersion = "1.2.0"

let project = Project(
    name: "AppStoreConnectMCP",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "MARKETING_VERSION": .string(mcpVersion),
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ]
    ),
    targets: [
        .target(
            name: "AppStoreConnectMCP",
            destinations: [.mac],
            product: .commandLineTool,
            bundleId: "com.appstoreconnect.mcp",
            deploymentTargets: .macOS("13.0"),
            sources: ["Sources/AppStoreConnectMCP/**"],
            dependencies: [
                .external(name: "MCP"),
            ]
        ),
        .target(
            name: "AppStoreConnectMCPTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.appstoreconnect.mcp.tests",
            deploymentTargets: .macOS("13.0"),
            sources: ["Tests/AppStoreConnectMCPTests/**"],
            dependencies: [
                .target(name: "AppStoreConnectMCP"),
            ]
        ),
    ]
)
