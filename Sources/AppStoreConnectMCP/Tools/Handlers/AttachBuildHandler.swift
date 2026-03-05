import Foundation
import MCP

struct AttachBuildHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let versionID) = args["version_id"] else {
            throw AppStoreConnectError.invalidArgument("version_id is required")
        }
        guard case .string(let buildID) = args["build_id"] else {
            throw AppStoreConnectError.invalidArgument("build_id is required")
        }

        let relationshipBody = RelationshipData(
            data: .init(type: "builds", id: buildID)
        )

        try await client.patchNoContent(
            Endpoints.versionBuildRelationship(versionID: versionID),
            body: relationshipBody
        )

        return CallTool.Result(content: [.text(
            "Attached build [\(buildID)] to version [\(versionID)]"
        )])
    }
}
