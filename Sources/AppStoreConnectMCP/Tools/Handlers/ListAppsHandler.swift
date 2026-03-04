import Foundation
import MCP

struct ListAppsHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let response = try await client.get(Endpoints.apps(), as: APIListResponse<App>.self)

        let lines = response.data.map { app in
            "[\(app.id)] \(app.attributes.name) (\(app.attributes.bundleId))"
        }

        let output = lines.isEmpty ? "No apps found." : lines.joined(separator: "\n")
        return CallTool.Result(content: [.text(output)])
    }
}
