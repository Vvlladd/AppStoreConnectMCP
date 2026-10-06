# App Store Connect MCP Server

**Automate App Store Connect from your AI agent.**

## Overview

This MCP server lets AI agents like Claude Code, Claude Desktop, and Cursor manage your App Store Connect workflows through natural language. Create versions, update metadata, attach builds, and submit for review — all without leaving your editor.

Built in Swift with the [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk), it connects directly to the [App Store Connect REST API](https://developer.apple.com/documentation/appstoreconnectapi) using ES256 JWT authentication.

## Key Features

- **Release workflows** — Prepare releases, check status, validate before submission, and clone metadata between versions
- **Version management** — Create, update, and list App Store versions
- **Localized metadata** — Add descriptions, keywords, release notes, and URLs for any locale
- **Build management** — List builds, upload IPAs, and attach builds to versions
- **Diagnostics & performance** — View diagnostic signatures, logs, and performance metrics per build
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

> "Prepare version 2.1.0 for my app, validate it's ready for submission, and show me the full release status."

## Handshake Troubleshooting

If Codex reports JSON-RPC `-32603` with “The data couldn’t be read because it isn’t in the correct format” during startup, rebuild this revision and replace the executable referenced by your MCP configuration. The Swift SDK 0.12.1 decodes experimental client capabilities as strings; structured values can fail initialization. This server includes a compatibility transport that ignores unsupported experimental values while preserving standard capabilities.

Verify a built executable with:

```bash
python3 scripts/test-handshake.py /path/to/AppStoreConnectMCP
```

The check uses a temporary key and tests initialization, tool discovery, and `list_orgs` without contacting App Store Connect. Restart the MCP connection after replacing the executable.

## Available Tools

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| **Metadata Fetching** | | |
| `get_app` | Fetch name, bundle ID, SKU, primary locale, content rights, kids flag, and accessibility URL | `app_id` |
| `list_app_infos` | Fetch all app-info records with states, age ratings, and category IDs | `app_id` |
| `list_app_info_localizations` | Fetch localized names, subtitles, privacy URLs, and privacy policy text | `app_info_id`, `locale?` |
| `update_app_info_localization` | Update an existing localized app name and/or subtitle | `app_info_id`, `locale`, `name?`, `subtitle?` |
| `get_version` | Fetch version state, copyright, release settings, dates, review type, and flags | `version_id` |
| `list_version_localizations` | Fetch keywords, descriptions, release notes, promotional text, and marketing/support URLs | `version_id`, `locale?` |
| **Release Workflows** | | |
| `prepare_release` | Check readiness, create version, attach build, sync metadata | `app_id`, `version_string`, `platform` |
| `release_status` | Full status overview: state, build, localizations, release type | `app_id`, `version_id?`, `platform?` |
| `validate_for_submission` | Pre-submit checklist with pass/fail for each requirement | `app_id`, `version_id?`, `platform?` |
| `clone_version_metadata` | Copy all localizations from one version to another | `source_version_id`, `target_version_id`, `locales?` |
| **Version Management** | | |
| `list_apps` | List all apps in your account | — |
| `create_version` | Create a new App Store version | `app_id`, `version_string`, `platform` |
| `list_versions` | List existing versions for an app | `app_id`, `platform?` |
| `update_version` | Update version attributes | `version_id`, `copyright?`, `release_type?` |
| `add_localization` | Add/update localized metadata | `version_id`, `locale`, `description?`, `keywords?`, `whats_new?`, `promotional_text?`, `marketing_url?`, `support_url?` |
| **Build Management** | | |
| `list_builds` | List available builds | `app_id`, `limit?` |
| `upload_build` | Upload an IPA to App Store Connect | `app_id`, `ipa_path`, `version_string`, `build_number`, `platform?` |
| `attach_build` | Attach a build to a version | `version_id`, `build_id` |
| **Review** | | |
| `submit_for_review` | Submit a version for App Review | `version_id` |
| **Diagnostics & Performance** | | |
| `list_diagnostic_signatures` | List diagnostic signatures (hangs, disk writes) for a build | `build_id`, `diagnostic_type?`, `limit?` |
| `get_diagnostic_logs` | Get detailed logs with stack traces for a diagnostic signature | `signature_id` |
| `get_perf_metrics` | Get performance and power metrics for an app or build | `app_id` or `build_id`, `metric_type?`, `platform?` |
| **Organization** | | |
| `list_orgs` | List configured organizations | — |
| `set_default_org` | Change the default organization | `org` |

All tools (except `list_orgs` and `set_default_org`) accept an optional `org` parameter to target a specific organization.

To fetch store metadata, start with `list_apps` to get the app ID. Use `list_app_infos`
to find the app-info record you want, then pass its ID to `list_app_info_localizations`
for names, subtitles, and privacy fields. App-info records can represent live or
upcoming metadata; the output includes each record's state and ID.

Use `update_app_info_localization` with the selected `app_info_id`, an existing
`locale`, and at least one of `name` or `subtitle`. Omitted fields are preserved;
an empty subtitle clears it. Select the draft app-info record to change upcoming
metadata. This tool does not create missing locales.

For keywords and descriptions, use `list_versions` to choose the version and platform,
then call `list_version_localizations` with its version ID. Both localization tools
accept an optional `locale` filter and follow all pagination links. Full text is
returned without truncation; missing or empty fields are shown as `(not set)`.

For example: “Fetch the English name, subtitle, keywords, description, and privacy
policy URL for my app's current iOS release.”

Verify metadata decoding and formatting with `./scripts/test-metadata.sh`. After
building, run `python3 scripts/test-handshake.py /path/to/AppStoreConnectMCP` to
check tool discovery and argument validation. These checks use fixtures and a
temporary key without contacting App Store Connect.

`./scripts/test-release-metadata.sh` tests draft release checks and localized
name/subtitle updates against fixtures. It uses the frameworks from a release
build; pass another build's product directory as its first argument if needed.

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
