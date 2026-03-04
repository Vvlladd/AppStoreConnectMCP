// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        baseSettings: .settings(
            base: [
                "SWIFT_VERSION": "6.0",
            ]
        )
    )
#endif

let package = Package(
    name: "AppStoreConnectMCP",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(
            url: "https://github.com/modelcontextprotocol/swift-sdk.git",
            from: "0.7.1"
        ),
    ]
)
