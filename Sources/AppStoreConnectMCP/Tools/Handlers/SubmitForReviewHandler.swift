import Foundation
import MCP

struct SubmitForReviewHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let versionID) = args["version_id"] else {
            throw AppStoreConnectError.invalidArgument("version_id is required")
        }

        let body = CreateSubmissionRequest(
            data: .init(
                relationships: .init(
                    appStoreVersion: .init(data: .init(type: "appStoreVersions", id: versionID))
                )
            )
        )

        let response = try await client.post(
            Endpoints.appStoreVersionSubmissions(),
            body: body,
            as: APIResponse<AppStoreReviewSubmission>.self
        )

        return CallTool.Result(content: [.text(
            "Submitted version [\(versionID)] for review — submission ID: \(response.data.id)"
        )])
    }
}
