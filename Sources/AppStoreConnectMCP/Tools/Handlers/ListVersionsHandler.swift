import Foundation
import MCP

struct ListVersionsHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let appID) = args["app_id"] else {
            throw AppStoreConnectError.invalidArgument("app_id is required")
        }
        let platform: String? = if case .string(let v) = args["platform"] { v } else { nil }

        let url = Endpoints.appStoreVersions(appID: appID, platform: platform)
        let response = try await client.get(url, as: APIListResponse<AppStoreVersion>.self)

        let lines = response.data.map { v in
            "[\(v.id)] v\(v.attributes.versionString ?? "?") — \(v.attributes.platform ?? "?") — \(v.attributes.appStoreState ?? "?")"
        }

        let output = lines.isEmpty ? "No versions found." : lines.joined(separator: "\n")
        return CallTool.Result(content: [.text(output)])
    }
}
