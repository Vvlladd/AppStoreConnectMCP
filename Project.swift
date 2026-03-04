import ProjectDescription

let project = Project(
    name: "AppStoreConnectMCP",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
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
    ]
)
