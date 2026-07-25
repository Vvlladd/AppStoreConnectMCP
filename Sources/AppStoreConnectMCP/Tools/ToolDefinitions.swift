import MCP

enum ToolDefinitions {
    static let allTools: [Tool] = [
        listApps,
        createVersion,
        listVersions,
        updateVersion,
        setPhasedRelease,
        addLocalization,
        listBuilds,
        uploadBuild,
        attachBuild,
        prepareRelease,
        submitForReview,
        releaseVersion,
        releaseStatus,
        cloneVersionMetadata,
        validateForSubmission,
        listOrgs,
        setDefaultOrg,
        listDiagnosticSignatures,
        getDiagnosticLogs,
        getPerfMetrics,
    ]

    private static let orgProp = prop("string", "Organization name (optional, uses default if omitted)")

    private static func prop(_ type: String, _ description: String) -> Value {
        .object(["type": .string(type), "description": .string(description)])
    }

    private static func schema(properties: [String: Value], required: [String] = []) -> Value {
        var props = properties
        props["org"] = orgProp
        var obj: [String: Value] = [
            "type": .string("object"),
            "properties": .object(props),
        ]
        if !required.isEmpty {
            obj["required"] = .array(required.map { .string($0) })
        }
        return .object(obj)
    }

    static let listApps = Tool(
        name: "list_apps",
        description: "List all apps in your App Store Connect account",
        inputSchema: schema(properties: [:])
    )

    static let createVersion = Tool(
        name: "create_version",
        description: "Create a new App Store version for an app",
        inputSchema: schema(
            properties: [
                "app_id": prop("string", "The app ID"),
                "version_string": prop("string", "Version string (e.g. 1.2.0)"),
                "platform": prop("string", "Platform: IOS, MAC_OS, TV_OS, VISION_OS"),
                "copyright": prop("string", "Copyright text (optional)"),
                "release_type": prop("string", "MANUAL, AFTER_APPROVAL, or SCHEDULED (optional)"),
            ],
            required: ["app_id", "version_string", "platform"]
        )
    )

    static let listVersions = Tool(
        name: "list_versions",
        description: "List existing App Store versions for an app",
        inputSchema: schema(
            properties: [
                "app_id": prop("string", "The app ID"),
                "platform": prop("string", "Filter by platform (optional)"),
            ],
            required: ["app_id"]
        )
    )

    static let updateVersion = Tool(
        name: "update_version",
        description: "Update attributes of an existing App Store version",
        inputSchema: schema(
            properties: [
                "version_id": prop("string", "The version ID"),
                "copyright": prop("string", "Updated copyright text (optional)"),
                "release_type": prop("string", "MANUAL, AFTER_APPROVAL, or SCHEDULED (optional)"),
            ],
            required: ["version_id"]
        )
    )

    static let setPhasedRelease = Tool(
        name: "set_phased_release",
        description: "Choose whether an App Store version rolls out over 7 days or instantly to all users",
        inputSchema: schema(
            properties: [
                "version_id": prop("string", "The version ID"),
                "enabled": prop("boolean", "true for a 7-day phased rollout; false for instant rollout to all users"),
                "confirm_immediate_release": prop("boolean", "Must be true when disabling an active or paused phased release, because that immediately releases the version to all users"),
            ],
            required: ["version_id", "enabled"]
        )
    )

    static let addLocalization = Tool(
        name: "add_localization",
        description: "Add or update localized metadata for a version",
        inputSchema: schema(
            properties: [
                "version_id": prop("string", "The version ID"),
                "locale": prop("string", "Locale code (e.g. en-US, it, de-DE)"),
                "description": prop("string", "App description"),
                "keywords": prop("string", "Search keywords (comma-separated)"),
                "whats_new": prop("string", "What's new text (release notes)"),
                "promotional_text": prop("string", "Promotional text"),
                "marketing_url": prop("string", "Marketing URL"),
                "support_url": prop("string", "Support URL"),
            ],
            required: ["version_id", "locale"]
        )
    )

    static let listBuilds = Tool(
        name: "list_builds",
        description: "List available builds for an app",
        inputSchema: schema(
            properties: [
                "app_id": prop("string", "The app ID"),
                "limit": prop("integer", "Max results to return (default 10)"),
            ],
            required: ["app_id"]
        )
    )

    static let attachBuild = Tool(
        name: "attach_build",
        description: "Attach a build to an App Store version",
        inputSchema: schema(
            properties: [
                "version_id": prop("string", "The version ID"),
                "build_id": prop("string", "The build ID to attach"),
            ],
            required: ["version_id", "build_id"]
        )
    )

    static let uploadBuild = Tool(
        name: "upload_build",
        description: "Create a build upload, upload an IPA file, and mark the upload complete",
        inputSchema: schema(
            properties: [
                "app_id": prop("string", "The app ID"),
                "ipa_path": prop("string", "Absolute path to the IPA file"),
                "version_string": prop("string", "Marketing version for the build upload (e.g. 1.2.0)"),
                "build_number": prop("string", "Build number for the upload (e.g. 123)"),
                "platform": prop("string", "Platform: IOS, MAC_OS, TV_OS, VISION_OS (default IOS)"),
                "asset_type": prop("string", "Build asset type (default ASSET)"),
                "uti": prop("string", "Uniform type identifier for the file (default com.apple.ipa)"),
            ],
            required: ["app_id", "ipa_path", "version_string", "build_number"]
        )
    )

    static let prepareRelease = Tool(
        name: "prepare_release",
        description: "Check release readiness, create or reuse a version, attach the latest valid build, ensure metadata is present, and optionally configure rollout",
        inputSchema: schema(
            properties: [
                "app_id": prop("string", "The app ID"),
                "version_string": prop("string", "Version string to prepare (e.g. 1.2.0)"),
                "platform": prop("string", "Platform: IOS, MAC_OS, TV_OS, VISION_OS"),
                "copyright": prop("string", "Copyright text to apply if needed"),
                "release_type": prop("string", "MANUAL, AFTER_APPROVAL, or SCHEDULED"),
                "phased_release": prop("boolean", "true for a 7-day phased rollout; false for instant rollout to all users"),
                "confirm_immediate_release": prop("boolean", "Must be true when disabling an active or paused phased release, because that immediately releases the version to all users"),
                "build_limit": prop("integer", "How many recent builds to inspect when selecting the latest valid build (default 100)"),
            ],
            required: ["app_id", "version_string", "platform"]
        )
    )

    static let submitForReview = Tool(
        name: "submit_for_review",
        description: "Submit an App Store version for App Review",
        inputSchema: schema(
            properties: [
                "version_id": prop("string", "The version ID to submit"),
            ],
            required: ["version_id"]
        )
    )

    static let releaseVersion = Tool(
        name: "release_version",
        description: "Release an approved App Store version that is in PENDING_DEVELOPER_RELEASE; this action cannot be canceled",
        inputSchema: schema(
            properties: [
                "version_id": prop("string", "The version ID to release"),
                "confirm": prop("boolean", "Must be true to confirm this irreversible action"),
            ],
            required: ["version_id", "confirm"]
        ),
        annotations: .init(
            title: "Release App Store Version",
            readOnlyHint: false,
            destructiveHint: true,
            idempotentHint: false,
            openWorldHint: true
        )
    )

    static let releaseStatus = Tool(
        name: "release_status",
        description: "Get the complete status of an App Store version: state, build info, localization completeness, release type, and rollout",
        inputSchema: schema(
            properties: [
                "app_id": prop("string", "The app ID"),
                "version_id": prop("string", "The version ID (optional, uses latest if omitted)"),
                "platform": prop("string", "Platform: IOS, MAC_OS, TV_OS, VISION_OS (default IOS)"),
            ],
            required: ["app_id"]
        )
    )

    static let cloneVersionMetadata = Tool(
        name: "clone_version_metadata",
        description: "Copy all localizations from one App Store version to another",
        inputSchema: schema(
            properties: [
                "source_version_id": prop("string", "The source version ID to copy from"),
                "target_version_id": prop("string", "The target version ID to copy to"),
                "locales": prop("string", "Comma-separated locale codes to clone (optional, clones all if omitted)"),
            ],
            required: ["source_version_id", "target_version_id"]
        )
    )

    static let validateForSubmission = Tool(
        name: "validate_for_submission",
        description: "Pre-submission checklist: checks build, localizations, copyright, and version state before submitting for review",
        inputSchema: schema(
            properties: [
                "app_id": prop("string", "The app ID"),
                "version_id": prop("string", "The version ID (optional, uses latest if omitted)"),
                "platform": prop("string", "Platform: IOS, MAC_OS, TV_OS, VISION_OS (default IOS)"),
            ],
            required: ["app_id"]
        )
    )

    static let listOrgs = Tool(
        name: "list_orgs",
        description: "List all configured App Store Connect organizations",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([:]),
        ])
    )

    static let listDiagnosticSignatures = Tool(
        name: "list_diagnostic_signatures",
        description: "List diagnostic signatures (hangs, disk writes) for a build, with severity weights",
        inputSchema: schema(
            properties: [
                "build_id": prop("string", "The build ID"),
                "diagnostic_type": prop("string", "Filter by type: DISK_WRITES or HANGS (optional)"),
                "limit": prop("integer", "Max results to return (default 10)"),
            ],
            required: ["build_id"]
        )
    )

    static let getDiagnosticLogs = Tool(
        name: "get_diagnostic_logs",
        description: "Get detailed diagnostic logs with stack traces, device info, and metadata for a diagnostic signature",
        inputSchema: schema(
            properties: [
                "signature_id": prop("string", "The diagnostic signature ID"),
            ],
            required: ["signature_id"]
        )
    )

    static let getPerfMetrics = Tool(
        name: "get_perf_metrics",
        description: "Get performance and power metrics (launch times, hang rates, memory, battery, disk writes) for an app or build",
        inputSchema: schema(
            properties: [
                "app_id": prop("string", "The app ID (provide app_id or build_id)"),
                "build_id": prop("string", "The build ID (provide app_id or build_id)"),
                "metric_type": prop("string", "Filter by metric type (optional)"),
                "platform": prop("string", "Filter by platform: IOS, MAC_OS, TV_OS, VISION_OS (optional)"),
            ]
        )
    )

    static let setDefaultOrg = Tool(
        name: "set_default_org",
        description: "Set the default organization for subsequent tool calls",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "org_name": prop("string", "The organization name to set as default"),
            ]),
            "required": .array([.string("org_name")]),
        ])
    )
}
