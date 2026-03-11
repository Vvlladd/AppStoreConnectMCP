# Contributing

## Branching

- Branch off `main` for all changes
- Use descriptive branch names:

      feature/add-list-reviews-tool
      bugfix/fix-jwt-expiry-handling

- At least one approval from [Vlad](https://github.com/Vvlladd) or [Max](https://github.com/maxhartung) is required is required before merging

---

## Project Setup

1. Clone the repo
2. Run `./bootstrap.sh` to install Tuist, fetch dependencies, and open in Xcode
3. Set environment variables (see README.md and the [Multi-Org Support](#multi-org-support) section below)
4. Build with `tuist build` or `Cmd+B` in Xcode

## Adding a New MCP Tool

Every new tool follows a 5-step pattern:

### 1. Model (`API/Models/`)

Add Codable structs matching the Apple API response:

```swift
struct MyResource: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        // fields from API docs
    }
}
```

### 2. Endpoint (`API/Endpoints.swift`)

Add a static URL builder:

```swift
static func myResource(appID: String) -> URL {
    URL(string: "\(base)/apps/\(appID)/myResource")!
}
```

### 3. Handler (`Tools/Handlers/`)

Create a new handler file. Most tools accept an optional `org` parameter — pass it through to `OrganizationRegistry` to resolve the correct client:

```swift
struct MyToolHandler {
    let registry: OrganizationRegistry

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments,
              case .string(let appID) = args["app_id"] else {
            throw AppStoreConnectError.invalidArgument("app_id is required")
        }

        // Resolve org (nil = use default)
        let orgID: String?
        if case .string(let o) = args["org"] { orgID = o } else { orgID = nil }
        let client = try await registry.client(for: orgID)

        let response = try await client.get(
            Endpoints.myResource(appID: appID),
            as: APIListResponse<MyResource>.self
        )

        let output = // format response as readable text
        return CallTool.Result(content: [.text(output)])
    }
}
```

### 4. Tool Definition (`Tools/ToolDefinitions.swift`)

Add the schema and include it in `allTools`:

```swift
static let myTool = Tool(
    name: "my_tool",
    description: "What it does",
    inputSchema: schema(
        properties: [
            "app_id": prop("string", "The app ID"),
        ],
        required: ["app_id"]
    )
)
```

### 5. Router (`Tools/ToolRouter.swift`)

Add the handler property, initialize it, and add the routing case:

```swift
private let myTool: MyToolHandler

// In init:
self.myTool = MyToolHandler(client: client)

// In route():
case "my_tool": return try await myTool.handle(params)
```

## Multi-Org Support

The server supports multiple App Store Connect organizations in a single instance. All tools (except `list_orgs` and `set_default_org`) accept an optional `org` parameter.

**Environment variables** — configure one or more orgs using the `ASC_ORG_<name>_*` prefix:

```bash
ASC_ORG_acme_ISSUER_ID=xxx
ASC_ORG_acme_KEY_ID=yyy
ASC_ORG_acme_PRIVATE_KEY_PATH=/path/to/acme.p8
ASC_ORG_acme_AUTH_MODE=team       # "team" (default) or "individual"

ASC_ORG_startup_ISSUER_ID=aaa
ASC_ORG_startup_KEY_ID=bbb
ASC_ORG_startup_PRIVATE_KEY_PATH=/path/to/startup.p8

ASC_DEFAULT_ORG=acme              # optional, defaults to first org alphabetically
```

When multi-org vars are present, the legacy single-org vars (`ASC_ISSUER_ID`, `ASC_KEY_ID`, `ASC_PRIVATE_KEY_PATH`) are ignored.

Use `list_orgs` to inspect configured organizations and `set_default_org` to change the default at runtime.

## Code Guidelines

- **One handler per file** — keeps things easy to find
- **Always return text** — the AI agent reads plain text, format results as human-readable strings
- **Never crash** — all errors should be caught and returned as `CallTool.Result(content: [.text(error)], isError: true)`
- **Validate arguments early** — check required params at the top of the handler
- Swift 6.0 strict concurrency — all types should be `Sendable`
- Actors for shared mutable state (`JWTGenerator`, `AppStoreConnectClient`)
- No third-party dependencies beyond the MCP SDK

## Testing a New Tool

1. Build: `tuist build`
2. Test with MCP Inspector: `npx @modelcontextprotocol/inspector .build/debug/AppStoreConnectMCP`
3. Or test via Claude Code (see README for config)
4. Verify results match what you see in [App Store Connect](https://appstoreconnect.apple.com)

## Useful Resources

- [App Store Connect API docs](https://developer.apple.com/documentation/appstoreconnectapi)
- [MCP specification](https://modelcontextprotocol.io)
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk)
