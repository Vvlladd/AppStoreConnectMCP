# App Store Connect MCP Server

## Project Overview

A Swift MCP (Model Context Protocol) server that exposes App Store Connect REST API operations as tools for AI agents. Built as a macOS command-line tool using Tuist for project generation.

## Tech Stack

- **Language:** Swift 6.0 (strict concurrency)
- **Build system:** Tuist 4.x (`Project.swift`, `Tuist/Package.swift`)
- **Dependencies:** MCP Swift SDK (`modelcontextprotocol/swift-sdk` 0.7.1+)
- **Platform:** macOS 13+
- **Auth:** ES256 JWT signing via Apple CryptoKit

## Architecture

```
Sources/AppStoreConnectMCP/
  main.swift              — Entry point: server setup + stdio transport
  Configuration.swift     — Loads env vars (ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH)
  Auth/JWTGenerator.swift — JWT token generation
  API/
    AppStoreConnectClient.swift — HTTP client with auto-retry on 401/429
    Endpoints.swift             — URL builders
    Models/                     — Codable request/response types (JSON:API format)
  Tools/
    ToolDefinitions.swift       — MCP tool schemas (JSON Schema)
    ToolRouter.swift            — Dispatches tool calls to handlers
    Handlers/                   — One handler per tool
```

## Available MCP Tools

`list_apps`, `create_version`, `list_versions`, `update_version`, `add_localization`, `list_builds`, `attach_build`, `submit_for_review`

## Build & Run

```bash
tuist install     # Fetch dependencies
tuist generate    # Generate Xcode project
tuist build       # Build via CLI
```

Or use `./bootstrap.sh` which does all three and opens Xcode.

## Adding a New Tool

1. Add model in `API/Models/`
2. Add endpoint in `API/Endpoints.swift`
3. Create handler in `Tools/Handlers/`
4. Register schema in `Tools/ToolDefinitions.swift` + add to `allTools`
5. Wire up in `Tools/ToolRouter.swift`

## Conventions

- All types are `Sendable` (Swift 6 strict concurrency)
- Handlers extract params from `CallTool.Parameters.arguments` dictionary
- Tool output is plain text formatted for readability (e.g., `[id] name (bundle_id)`)
- API responses follow Apple's JSON:API format — use `APIListResponse<T>` / `APIResponse<T>` wrappers
- Use `AppStoreConnectError` for error cases

## Environment Variables

Required at runtime:
- `ASC_ISSUER_ID` — App Store Connect API issuer ID
- `ASC_KEY_ID` — API key ID
- `ASC_PRIVATE_KEY_PATH` — Path to `.p8` private key file
