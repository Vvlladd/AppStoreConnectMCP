# unPi way of working

1. Branching: 

  <img width="1193" alt="Screenshot 2023-09-21 at 14 22 54" src="https://github.com/unPi-ro/template/assets/88333833/b5269f3c-7ac7-4dc9-827e-92f7a391c969">

2. Branch naming example:

     feature/add-human-cats-and-dogs-classifier
   
     bugfix/change-main-button-size
      
4. At least one approval from [Ciprian](https://github.com/cipy) or [Vlad](https://github.com/Vvlladd) is required

---

## Project Setup

1. Clone the repo
2. Run `./bootstrap.sh` to install Tuist, fetch dependencies, and open in Xcode
3. Set environment variables (see README.md)
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

Create a new handler file:

```swift
struct MyToolHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments,
              case .string(let appID) = args["app_id"] else {
            throw AppStoreConnectError.invalidArgument("app_id is required")
        }

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
