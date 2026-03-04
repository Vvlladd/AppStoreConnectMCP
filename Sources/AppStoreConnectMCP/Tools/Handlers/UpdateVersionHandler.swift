import Foundation
import MCP

struct UpdateVersionHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let versionID) = args["version_id"] else {
            throw AppStoreConnectError.invalidArgument("version_id is required")
        }

        let copyright: String? = if case .string(let v) = args["copyright"] { v } else { nil }
        let releaseType: String? = if case .string(let v) = args["release_type"] { v } else { nil }

        let body = UpdateVersionRequest(
            data: .init(
                id: versionID,
                attributes: .init(copyright: copyright, releaseType: releaseType)
            )
        )

        let response = try await client.patch(
            Endpoints.appStoreVersion(id: versionID), body: body, as: APIResponse<AppStoreVersion>.self
        )
        let v = response.data
        return CallTool.Result(content: [.text(
            "Updated version [\(v.id)] — copyright: \(v.attributes.copyright ?? "n/a"), releaseType: \(v.attributes.releaseType ?? "n/a")"
        )])
    }
}
