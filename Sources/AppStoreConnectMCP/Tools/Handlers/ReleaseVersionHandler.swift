import Foundation
import MCP

struct ReleaseVersionHandler {
    private static let releasableState = "PENDING_DEVELOPER_RELEASE"

    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let versionID) = args["version_id"] else {
            throw AppStoreConnectError.invalidArgument("version_id is required")
        }

        let versionResponse = try await client.get(
            Endpoints.appStoreVersion(id: versionID),
            as: APIResponse<AppStoreVersion>.self
        )
        let version = versionResponse.data
        let state = version.attributes.appStoreState ?? "UNKNOWN"

        guard state == Self.releasableState else {
            throw AppStoreConnectError.invalidArgument(
                "Version [\(versionID)] cannot be released from state \(state); expected \(Self.releasableState)"
            )
        }

        let body = CreateAppStoreVersionReleaseRequest(versionID: versionID)
        let response = try await client.post(
            Endpoints.appStoreVersionReleaseRequests(),
            body: body,
            as: APIResponse<AppStoreVersionReleaseRequest>.self
        )

        let versionLabel = version.attributes.versionString.map { " v\($0)" } ?? ""
        return CallTool.Result(content: [.text(
            "Release requested for version\(versionLabel) [\(versionID)] — request ID: \(response.data.id)"
        )])
    }
}
