import Foundation
import MCP

struct SetPhasedReleaseHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let rawVersionID) = args["version_id"] else {
            throw AppStoreConnectError.invalidArgument("version_id is required")
        }
        let versionID = rawVersionID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !versionID.isEmpty else {
            throw AppStoreConnectError.invalidArgument("version_id must not be empty")
        }
        guard case .bool(let enabled) = args["enabled"] else {
            throw AppStoreConnectError.invalidArgument("enabled is required and must be a boolean")
        }
        let confirmImmediateRelease: Bool
        if let value = args["confirm_immediate_release"] {
            guard case .bool(let confirmed) = value else {
                throw AppStoreConnectError.invalidArgument(
                    "confirm_immediate_release must be a boolean"
                )
            }
            confirmImmediateRelease = confirmed
        } else {
            confirmImmediateRelease = false
        }

        let result = try await PhasedReleaseManager(client: client).setEnabled(
            enabled,
            forVersionID: versionID,
            confirmImmediateRelease: confirmImmediateRelease
        )
        let action = result.changed ? "Set" : "Kept"
        return CallTool.Result(content: [.text(
            text: "\(action) version [\(versionID)] to \(result.description)",
            annotations: nil,
            _meta: nil
        )])
    }
}
