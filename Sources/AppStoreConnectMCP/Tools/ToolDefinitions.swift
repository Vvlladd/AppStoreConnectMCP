import MCP

enum ToolDefinitions {
    static let allTools: [Tool] = [
        listApps,
        createVersion,
        listVersions,
        updateVersion,
        addLocalization,
        listBuilds,
        attachBuild,
        submitForReview,
    ]

    private static func prop(_ type: String, _ description: String) -> Value {
        .object(["type": .string(type), "description": .string(description)])
    }

    private static func schema(properties: [String: Value], required: [String] = []) -> Value {
        var obj: [String: Value] = [
            "type": .string("object"),
            "properties": .object(properties),
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
}
