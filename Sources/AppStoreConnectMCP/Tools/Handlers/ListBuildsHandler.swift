import Foundation
import MCP

struct ListBuildsHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let appID) = args["app_id"] else {
            throw AppStoreConnectError.invalidArgument("app_id is required")
        }

        let limit: Int
        if let n = args["limit"]?.intValue {
            limit = n
        } else {
            limit = 10
        }

        let response = try await client.get(
            Endpoints.builds(appID: appID, limit: limit),
            as: APIListResponse<Build>.self
        )

        let lines = response.data.map { b in
            "[\(b.id)] v\(b.attributes.version ?? "?") build \(b.attributes.buildNumber ?? "?") — \(b.attributes.processingState ?? "?") — \(b.attributes.uploadedDate ?? "?")"
        }

        let output = lines.isEmpty ? "No builds found." : lines.joined(separator: "\n")
        return CallTool.Result(content: [.text(output)])
    }
}
