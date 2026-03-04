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

        // Update the version to attach the build via relationship
        let body = UpdateVersionRequest(
            data: .init(
                id: versionID,
                attributes: .init(copyright: nil, releaseType: nil)
            )
        )

        // The build attachment is done via the version's build relationship endpoint
        let relationshipBody = RelationshipData(
            data: .init(type: "builds", id: buildID)
        )

        // PATCH /v1/appStoreVersions/{id}/relationships/build
        let url = URL(string: "https://api.appstoreconnect.apple.com/v1/appStoreVersions/\(versionID)/relationships/build")!
        _ = try await client.patch(url, body: relationshipBody, as: APIResponse<AppStoreVersion>.self)

        return CallTool.Result(content: [.text(
            "Attached build [\(buildID)] to version [\(versionID)]"
        )])
    }
}
