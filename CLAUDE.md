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
  main.swift                — Entry point: server setup + stdio transport
  Configuration.swift       — Loads env vars (single + multi-org)
  OrganizationRegistry.swift — Multi-org registry (actor)
  Auth/JWTGenerator.swift   — JWT token generation
  Logging/MCPLogger.swift   — Stderr-based structured log handler
  API/
    AppStoreConnectClient.swift — HTTP client with auto-retry on 401/429
    Endpoints.swift             — URL builders
    Models/                     — Codable request/response types (JSON:API format)
  Tools/
    ToolDefinitions.swift       — MCP tool schemas (JSON Schema)
    ToolRouter.swift            — Dispatches tool calls to handlers via OrganizationRegistry
    Handlers/                   — One handler per tool
```

## Available MCP Tools

`list_apps`, `create_version`, `list_versions`, `update_version`, `add_localization`, `list_builds`, `attach_build`, `submit_for_review`, `list_orgs`, `set_default_org`

All tools (except `list_orgs` and `set_default_org`) accept an optional `org` parameter to target a specific organization.

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

### Single Organization (legacy)

- `ASC_ISSUER_ID` — App Store Connect API issuer ID
- `ASC_KEY_ID` — API key ID
- `ASC_PRIVATE_KEY_PATH` — Path to `.p8` private key file
- `ASC_AUTH_MODE` — `team` (default) or `individual`

### Multi-Organization

```bash
ASC_ORG_acme_ISSUER_ID=xxx
ASC_ORG_acme_KEY_ID=yyy
ASC_ORG_acme_PRIVATE_KEY_PATH=/path/to/acme.p8
ASC_ORG_acme_AUTH_MODE=team

ASC_ORG_startup_ISSUER_ID=aaa
ASC_ORG_startup_KEY_ID=bbb
ASC_ORG_startup_PRIVATE_KEY_PATH=/path/to/startup.p8

ASC_DEFAULT_ORG=acme   # optional, defaults to first org alphabetically
```

When multi-org env vars are present, legacy single-org vars are ignored. Use `list_orgs` to see configured organizations and `set_default_org` to change the default at runtime.
