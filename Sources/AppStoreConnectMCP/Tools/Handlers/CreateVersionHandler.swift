import Foundation
import MCP

struct CreateVersionHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let appID) = args["app_id"] else {
            throw AppStoreConnectError.invalidArgument("app_id is required")
        }
        guard case .string(let versionString) = args["version_string"] else {
            throw AppStoreConnectError.invalidArgument("version_string is required")
        }
        guard case .string(let platform) = args["platform"] else {
            throw AppStoreConnectError.invalidArgument("platform is required")
        }

        let copyright: String? = if case .string(let v) = args["copyright"] { v } else { nil }
        let releaseType: String? = if case .string(let v) = args["release_type"] { v } else { nil }

        let body = CreateVersionRequest(
            data: .init(
                attributes: .init(
                    versionString: versionString,
                    platform: platform,
                    copyright: copyright,
                    releaseType: releaseType
                ),
                relationships: .init(
                    app: .init(data: .init(type: "apps", id: appID))
                )
            )
        )

        let response = try await client.post(
            Endpoints.appStoreVersionsCreate(), body: body, as: APIResponse<AppStoreVersion>.self
        )
        let v = response.data
        return CallTool.Result(content: [.text(
            "Created version \(v.attributes.versionString ?? "") [\(v.id)] — state: \(v.attributes.appStoreState ?? "unknown")"
        )])
    }
}
