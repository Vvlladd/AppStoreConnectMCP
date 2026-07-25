import ProjectDescription

let mcpVersion = "1.3.0"

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
            // A command-line tool has no bundle, so `Bundle.main.infoDictionary` is only
            // populated when the plist is embedded in the binary. Without this the server
            // advertises its fallback version ("0.0.0") to MCP clients.
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": .string(mcpVersion),
            ]),
            sources: ["Sources/AppStoreConnectMCP/**"],
            dependencies: [
                .external(name: "MCP"),
            ],
            settings: .settings(
                base: [
                    "CREATE_INFOPLIST_SECTION_IN_BINARY": "YES",
                ]
            )
        ),
        // The product under test is a command-line tool, so it cannot act as a test host
        // and its symbols are not linkable from a test bundle. Compile the sources into
        // the test bundle instead (everything except `main.swift`, whose top-level code
        // is only valid in an executable). The shipped binary is unaffected.
        .target(
            name: "AppStoreConnectMCPTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.appstoreconnect.mcp.tests",
            deploymentTargets: .macOS("13.0"),
            sources: [
                "Tests/AppStoreConnectMCPTests/**",
                .glob(
                    "Sources/AppStoreConnectMCP/**",
                    excluding: ["Sources/AppStoreConnectMCP/main.swift"]
                ),
            ],
            dependencies: [
                .external(name: "MCP"),
            ]
        ),
    ]
)
