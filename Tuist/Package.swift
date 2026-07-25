// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    // Several transitive dependencies (swift-nio, swift-atomics, swift-collections, …)
    // declare no `platforms:`, so Tuist falls back to macOS 10.13 for their generated
    // targets. Xcode 27 rejects anything below 12.0, which fails the whole build. Pin
    // every external target to our own macOS 13 floor.
    //
    // Base settings alone are not enough — Tuist writes the deployment target at target
    // level, which wins over the project-level base. To refresh this list after changing
    // dependencies, take the target names from the `MACOSX_DEPLOYMENT_TARGET is set to
    // 10.13` build errors.
    let macOSDeploymentTarget: SettingsDictionary = ["MACOSX_DEPLOYMENT_TARGET": "13.0"]

    let externalTargets = [
        "AsyncAlgorithms",
        "Atomics",
        "CNIOAtomics",
        "CNIODarwin",
        "CNIOLinux",
        "CNIOOpenBSD",
        "CNIOWASI",
        "CNIOWindows",
        "CSystem",
        "DequeModule",
        "EventSource",
        "InternalCollectionsUtilities",
        "Logging",
        "MCP",
        "NIOConcurrencyHelpers",
        "NIOCore",
        "SystemPackage",
        "_AtomicsShims",
        "_NIOBase64",
        "_NIODataStructures",
    ]

    let packageSettings = PackageSettings(
        baseSettings: .settings(
            base: [
                "SWIFT_VERSION": "6.0",
                "MACOSX_DEPLOYMENT_TARGET": "13.0",
            ]
        ),
        targetSettings: externalTargets.reduce(into: [String: SettingsDictionary]()) {
            $0[$1] = macOSDeploymentTarget
        }
    )
#endif

let package = Package(
    name: "AppStoreConnectMCP",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(
            url: "https://github.com/modelcontextprotocol/swift-sdk.git",
            from: "0.12.0"
        ),
    ]
)
