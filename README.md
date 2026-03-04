# App Store Connect MCP Server

An MCP (Model Context Protocol) server built in Swift that lets AI agents (Claude Code, Claude Desktop, Cursor, etc.) automate App Store Connect tasks via the [App Store Connect REST API](https://developer.apple.com/documentation/appstoreconnectapi).

## What It Does

This server exposes App Store Connect operations as MCP tools. When connected to an AI agent, you can use natural language to:

- **List your apps** — See all apps in your App Store Connect account
- **Manage versions** — Create new App Store versions, update version attributes (copyright, release type)
- **Manage metadata** — Add or update localized descriptions, keywords, release notes, promotional text, URLs for any locale
- **Manage builds** — List uploaded builds, attach a build to a version
- **Submit for review** — Submit a version to App Review

### Example Workflow

Tell your AI agent:
> "Create version 2.1.0 for my app, add Italian localization with description and release notes, attach the latest build, and submit for review."

The agent will call the tools in sequence: `list_apps` → `create_version` → `add_localization` → `list_builds` → `attach_build` → `submit_for_review`.

## Prerequisites

- Swift 6.0+ / Xcode 16+
- macOS 13+
- Tuist 4.x (`brew install tuist`)
- An [App Store Connect API key](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api) with **App Manager** role or higher

## Setup

### 1. Bootstrap

```bash
./bootstrap.sh
```

This installs Tuist if needed, fetches dependencies, and opens the project in Xcode.

Or manually:

```bash
tuist install
tuist generate
```

### 2. Environment Variables

Set these before running:

```bash
export ASC_ISSUER_ID="your-issuer-id"
export ASC_KEY_ID="your-key-id"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXXXXX.p8"
```

You can find these values in [App Store Connect > Users and Access > Integrations > App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api).

### 3. Build & Run

Build in Xcode (`Cmd+B`) or via CLI:

```bash
tuist build
```

## Available Tools

| Tool | Description | Key Params |
|------|-------------|------------|
| `list_apps` | List all apps in account | — |
| `create_version` | Create new App Store version | `app_id`, `version_string`, `platform` |
| `list_versions` | List existing versions for an app | `app_id`, `platform?` |
| `update_version` | Update version attributes | `version_id`, `copyright?`, `release_type?` |
| `add_localization` | Add/update localized metadata | `version_id`, `locale`, `description?`, `keywords?`, `whats_new?`, `promotional_text?`, `marketing_url?`, `support_url?` |
| `list_builds` | List available builds | `app_id`, `limit?` |
| `attach_build` | Attach build to version | `version_id`, `build_id` |
| `submit_for_review` | Submit version for App Review | `version_id` |

## Claude Code Configuration

Add to `~/.claude.json` (global) or `.claude/settings.json` (project):

```json
{
  "mcpServers": {
    "appstoreconnect": {
      "command": "/path/to/AppStoreConnectMCP/.build/debug/AppStoreConnectMCP",
      "env": {
        "ASC_ISSUER_ID": "your-issuer-id",
        "ASC_KEY_ID": "your-key-id",
        "ASC_PRIVATE_KEY_PATH": "/path/to/AuthKey.p8"
      }
    }
  }
}
```

## Architecture

```
Sources/AppStoreConnectMCP/
  main.swift                          # Entry point — server + stdio transport
  Configuration.swift                 # Loads env vars
  Auth/
    JWTGenerator.swift                # ES256 JWT signing with Apple CryptoKit
  API/
    AppStoreConnectClient.swift       # HTTP client (URLSession, auto-retry on 401/429)
    Endpoints.swift                   # URL builders for each API endpoint
    Models/                           # Codable request/response types
      App.swift
      AppStoreVersion.swift
      AppStoreVersionLocalization.swift
      Build.swift
      Submission.swift
      APIResponse.swift               # Generic JSON:API wrappers
      APIError.swift                  # Error enum
  Tools/
    ToolDefinitions.swift             # MCP tool schemas (JSON Schema)
    ToolRouter.swift                  # Dispatches tool calls to handlers
    Handlers/                         # One handler per tool
      ListAppsHandler.swift
      CreateVersionHandler.swift
      ...
```

## Adding New Tools

To add a new capability (e.g. managing screenshots, app pricing, or in-app purchases):

### 1. Add the API model

Create a new file in `API/Models/` with the Codable structs for the API response:

```swift
// API/Models/AppPrice.swift
struct AppPrice: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        // fields from the API
    }
}
```

### 2. Add the endpoint

Add a new static method in `API/Endpoints.swift`:

```swift
static func appPrices(appID: String) -> URL {
    URL(string: "\(base)/apps/\(appID)/prices")!
}
```

### 3. Create the handler

Add a new file in `Tools/Handlers/`:

```swift
// Tools/Handlers/ListPricesHandler.swift
struct ListPricesHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments,
              case .string(let appID) = args["app_id"] else {
            throw AppStoreConnectError.invalidArgument("app_id is required")
        }

        let response = try await client.get(
            Endpoints.appPrices(appID: appID),
            as: APIListResponse<AppPrice>.self
        )

        // Format output as text
        let output = response.data.map { "\($0.id): ..." }.joined(separator: "\n")
        return CallTool.Result(content: [.text(output)])
    }
}
```

### 4. Register the tool schema

Add the tool definition in `Tools/ToolDefinitions.swift`:

```swift
static let listPrices = Tool(
    name: "list_prices",
    description: "List price tiers for an app",
    inputSchema: schema(
        properties: [
            "app_id": prop("string", "The app ID"),
        ],
        required: ["app_id"]
    )
)
```

And add it to `allTools`:

```swift
static let allTools: [Tool] = [
    // ... existing tools
    listPrices,
]
```

### 5. Wire it up in the router

Add the handler and case in `Tools/ToolRouter.swift`:

```swift
private let listPrices: ListPricesHandler

// In init:
self.listPrices = ListPricesHandler(client: client)

// In route():
case "list_prices": return try await listPrices.handle(params)
```

That's it — rebuild and the new tool is available to any connected AI agent.

### Useful API References

- [App Store Connect API docs](https://developer.apple.com/documentation/appstoreconnectapi)
- [API endpoint reference](https://developer.apple.com/documentation/appstoreconnectapi/app_store)
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk)
