# App Store Connect MCP Server

**Automate App Store Connect from your AI agent.**

## Overview

This MCP server lets AI agents like Claude Code, Claude Desktop, and Cursor manage your App Store Connect workflows through natural language. Create versions, update metadata, attach builds, and submit for review — all without leaving your editor.

Built in Swift with the [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk), it connects directly to the [App Store Connect REST API](https://developer.apple.com/documentation/appstoreconnectapi) using ES256 JWT authentication.

## Key Features

- **Version management** — Create, update, and list App Store versions
- **Localized metadata** — Add descriptions, keywords, release notes, and URLs for any locale
- **Build management** — List builds, upload IPAs, and attach builds to versions
- **Review submission** — Submit versions to App Review in one step
- **Multi-organization** — Manage multiple App Store Connect teams from a single server
- **Secure auth** — ES256 JWT signing via Apple CryptoKit with automatic token refresh

## Build From Source (Setup)

Use this path if you want to work on or build this repository locally.

### Prerequisites

- macOS 13+, Swift 6.0+ / Xcode 16+
- [Tuist 4.x](https://docs.tuist.io/guides/quick-start/install-tuist) (`brew install tuist`)
- An [App Store Connect API key](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api) with **App Manager** role or higher

### Install and Build

```bash
./bootstrap.sh
```

This fetches dependencies, generates the Xcode project, and builds. Or manually:

```bash
tuist install && tuist generate && tuist build
```

### Configure

Set your API credentials:

```bash
export ASC_KEY_ID="your-key-id"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXXXXX.p8"
export ASC_ISSUER_ID="your-issuer-id"       # required for team keys
export ASC_AUTH_MODE="team"                  # "team" (default) or "individual"
```

Get these values from [App Store Connect > Users and Access > Integrations > App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api). For individual keys, set `ASC_AUTH_MODE="individual"` and omit `ASC_ISSUER_ID`.

## Install via npm

Use this path if you only want to run the MCP server and not build from source.

### Prerequisites

- Node.js 18+ and npm
- macOS

### Install/Run Command

```bash
npx -y @vvlladd/appstoreconnect-mcp
```

### Connect to Claude Code

Add to `~/.claude.json` (global) or `.claude/settings.json` (project) and use the npm package:

```json
{
  "mcpServers": {
    "appstoreconnect": {
      "command": "npx",
      "args": ["-y", "@vvlladd/appstoreconnect-mcp"],
      "env": {
        "ASC_KEY_ID": "your-key-id",
        "ASC_PRIVATE_KEY_PATH": "/path/to/AuthKey.p8",
        "ASC_ISSUER_ID": "your-issuer-id",
        "ASC_AUTH_MODE": "team"
      }
    }
  }
}
```

Then ask your agent something like:

> "Create version 2.1.0 for my app, add Italian localization with description and release notes, attach the latest build, and submit for review."

## Available Tools

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `list_apps` | List all apps in your account | — |
| `create_version` | Create a new App Store version | `app_id`, `version_string`, `platform` |
| `list_versions` | List existing versions for an app | `app_id`, `platform?` |
| `update_version` | Update version attributes | `version_id`, `copyright?`, `release_type?` |
| `add_localization` | Add/update localized metadata | `version_id`, `locale`, `description?`, `keywords?`, `whats_new?`, `promotional_text?`, `marketing_url?`, `support_url?` |
| `list_builds` | List available builds | `app_id`, `limit?` |
| `upload_build` | Upload an IPA to App Store Connect | `app_id`, `ipa_path`, `version_string`, `build_number`, `platform?` |
| `attach_build` | Attach a build to a version | `version_id`, `build_id` |
| `submit_for_review` | Submit a version for App Review | `version_id` |
| `list_orgs` | List configured organizations | — |
| `set_default_org` | Change the default organization | `org` |

All tools (except `list_orgs` and `set_default_org`) accept an optional `org` parameter to target a specific organization.

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `ASC_KEY_ID` | API key ID | Yes |
| `ASC_PRIVATE_KEY_PATH` | Path to `.p8` private key file | Yes |
| `ASC_ISSUER_ID` | API issuer ID | Team keys only |
| `ASC_AUTH_MODE` | `team` (default) or `individual` | No |

## Multi-Organization Support

Manage multiple App Store Connect teams by setting org-prefixed environment variables:

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

When multi-org variables are present, single-org variables are ignored. Use `list_orgs` to see configured organizations and `set_default_org` to switch at runtime.

## Architecture

```
Sources/AppStoreConnectMCP/
  main.swift                    — Entry point: server + stdio transport
  Configuration.swift           — Environment variable loading
  OrganizationRegistry.swift    — Multi-org registry (actor)
  Auth/JWTGenerator.swift       — ES256 JWT token generation
  Logging/MCPLogger.swift       — Stderr-based structured logging
  API/
    AppStoreConnectClient.swift — HTTP client with auto-retry (401/429)
    Endpoints.swift             — URL builders
    Models/                     — Codable request/response types (JSON:API)
  Tools/
    ToolDefinitions.swift       — MCP tool schemas
    ToolRouter.swift            — Tool call dispatch
    Handlers/                   — One handler per tool
```

## Reporting Issues

The GitHub Issues tab is disabled for security reasons. To report a bug or request a feature, please reach out directly to one of the maintainers:

- [Vlad](https://github.com/Vvlladd)
- [Max](https://github.com/maxhartung)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding new tools and development workflow.

## Links

- [App Store Connect API documentation](https://developer.apple.com/documentation/appstoreconnectapi)
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk)
- [Model Context Protocol specification](https://modelcontextprotocol.io)
