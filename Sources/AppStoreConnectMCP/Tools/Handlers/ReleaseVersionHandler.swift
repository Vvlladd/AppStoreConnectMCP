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
        guard !versionID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppStoreConnectError.invalidArgument("version_id must not be empty")
        }
        guard case .bool(true) = args["confirm"] else {
            throw AppStoreConnectError.invalidArgument(
                "confirm must be true because releasing a version cannot be canceled"
            )
        }

        let versionResponse = try await client.get(
            Endpoints.appStoreVersion(id: versionID),
            as: APIResponse<AppStoreVersion>.self
        )
        let version = versionResponse.data
        let state = version.attributes.appStoreState ?? "UNKNOWN"

        guard state == Self.releasableState else {
            throw AppStoreConnectError.invalidState(
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
            text: "Release requested for version\(versionLabel) [\(versionID)] — request ID: \(response.data.id)",
            annotations: nil,
            _meta: nil
        )])
    }
}
