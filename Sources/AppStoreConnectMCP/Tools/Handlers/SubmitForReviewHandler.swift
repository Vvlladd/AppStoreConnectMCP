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

        let versionLookup = try await client.get(
            Endpoints.appStoreVersion(id: versionID, includeApp: true),
            as: APIResponse<AppStoreVersionSubmissionLookup>.self
        )
        guard let appID = versionLookup.data.relationships?.app?.data?.id else {
            throw AppStoreConnectError.apiError("Could not resolve app ID from version \(versionID)")
        }

        let reviewSubmission = try await client.post(
            Endpoints.reviewSubmissions(),
            body: CreateReviewSubmissionRequest(appID: appID),
            as: APIResponse<ReviewSubmission>.self
        )

        let _ = try await client.post(
            Endpoints.reviewSubmissionItems(),
            body: CreateReviewSubmissionItemRequest(
                versionID: versionID,
                reviewSubmissionID: reviewSubmission.data.id
            ),
            as: APIResponse<ReviewSubmissionItem>.self
        )

        return CallTool.Result(content: [.text(
            "Submitted version [\(versionID)] for review — review submission ID: \(reviewSubmission.data.id)"
        )])
    }
}
