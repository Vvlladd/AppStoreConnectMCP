import Foundation
import MCP

struct SetPhasedReleaseHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let versionID) = args["version_id"] else {
            throw AppStoreConnectError.invalidArgument("version_id is required")
        }
        guard case .bool(let enabled) = args["enabled"] else {
            throw AppStoreConnectError.invalidArgument("enabled is required and must be a boolean")
        }

        let result = try await PhasedReleaseManager(client: client).setEnabled(
            enabled,
            forVersionID: versionID
        )
        let action = result.changed ? "Set" : "Kept"
        return CallTool.Result(content: [.text(
            "\(action) version [\(versionID)] to \(result.description)"
        )])
    }
}
