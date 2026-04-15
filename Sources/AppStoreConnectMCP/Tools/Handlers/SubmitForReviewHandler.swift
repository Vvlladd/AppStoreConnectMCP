import Foundation
import MCP

struct SubmitForReviewHandler {
    let client: AppStoreConnectClient

    private static let knownReviewSubmissionStates = [
        "READY_FOR_REVIEW",
        "WAITING_FOR_REVIEW",
        "IN_REVIEW",
        "UNRESOLVED_ISSUES",
        "CANCELING",
        "COMPLETING",
        "COMPLETE",
    ]

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

        let submissions = try await listReviewSubmissions(appID: appID)

        if let existingForVersion = submissions.first(where: { submission in
            submission.relationships?.appStoreVersionForReview?.data?.id == versionID
        }) {
            let state = existingForVersion.attributes?.state ?? "UNKNOWN"
            if state == "READY_FOR_REVIEW" {
                let submitted = try await submitReviewSubmission(reviewSubmissionID: existingForVersion.id)
                return CallTool.Result(content: [.text(
                    "Submitted version [\(versionID)] for review — review submission ID: \(submitted.id) (state: \(submitted.attributes?.state ?? "UNKNOWN"))"
                )])
            }

            return CallTool.Result(content: [.text(
                "Version [\(versionID)] is already in review submission [\(existingForVersion.id)] with state \(state)"
            )])
        }

        let (reviewSubmission, reusedExistingReadySubmission) = try await resolveOrCreateReadySubmission(
            appID: appID,
            existingSubmissions: submissions
        )

        let itemCreated = try await ensureSubmissionItem(
            reviewSubmissionID: reviewSubmission.id,
            versionID: versionID
        )

        let submitted = try await submitReviewSubmission(reviewSubmissionID: reviewSubmission.id)

        let reuseNote = reusedExistingReadySubmission ? "reused existing ready submission" : "created new submission"
        let itemNote = itemCreated ? "created submission item" : "submission item already existed"

        return CallTool.Result(content: [.text(
            "Submitted version [\(versionID)] for review — review submission ID: \(submitted.id) (state: \(submitted.attributes?.state ?? "UNKNOWN"), \(reuseNote), \(itemNote))"
        )])
    }

    private func listReviewSubmissions(appID: String) async throws -> [ReviewSubmission] {
        let response = try await client.get(
            Endpoints.reviewSubmissions(appID: appID, states: Self.knownReviewSubmissionStates),
            as: APIListResponse<ReviewSubmission>.self
        )
        return response.data
    }

    private func resolveOrCreateReadySubmission(
        appID: String,
        existingSubmissions: [ReviewSubmission]
    ) async throws -> (submission: ReviewSubmission, reusedExisting: Bool) {
        if let existingReady = existingSubmissions.first(where: { $0.attributes?.state == "READY_FOR_REVIEW" }) {
            return (existingReady, true)
        }

        do {
            let created = try await client.post(
                Endpoints.reviewSubmissions(),
                body: CreateReviewSubmissionRequest(appID: appID),
                as: APIResponse<ReviewSubmission>.self
            )
            return (created.data, false)
        } catch {
            guard isLikelyExistingSubmissionConflict(error) else {
                throw error
            }

            // Another process may have created the draft/ready submission just before us.
            let refreshed = try await listReviewSubmissions(appID: appID)
            if let existingReady = refreshed.first(where: { $0.attributes?.state == "READY_FOR_REVIEW" }) {
                return (existingReady, true)
            }
            throw error
        }
    }

    private func ensureSubmissionItem(reviewSubmissionID: String, versionID: String) async throws -> Bool {
        do {
            let _ = try await client.post(
                Endpoints.reviewSubmissionItems(),
                body: CreateReviewSubmissionItemRequest(
                    versionID: versionID,
                    reviewSubmissionID: reviewSubmissionID
                ),
                as: APIResponse<ReviewSubmissionItem>.self
            )
            return true
        } catch {
            if isLikelyDuplicateSubmissionItemError(error) {
                return false
            }
            throw error
        }
    }

    private func submitReviewSubmission(reviewSubmissionID: String) async throws -> ReviewSubmission {
        let response = try await client.patch(
            Endpoints.reviewSubmission(id: reviewSubmissionID),
            body: UpdateReviewSubmissionRequest(reviewSubmissionID: reviewSubmissionID, submitted: true),
            as: APIResponse<ReviewSubmission>.self
        )
        return response.data
    }

    private func isLikelyDuplicateSubmissionItemError(_ error: Error) -> Bool {
        let message: String
        switch error {
        case AppStoreConnectError.apiError(let apiMessage):
            message = apiMessage
        case AppStoreConnectError.httpError(let statusCode, let body):
            guard statusCode == 409 || statusCode == 422 else { return false }
            message = body
        default:
            return false
        }

        let normalized = message.lowercased()
        return normalized.contains("already")
            || normalized.contains("exists")
            || normalized.contains("reviewsubmissionitem")
            || normalized.contains("review submission item")
    }

    private func isLikelyExistingSubmissionConflict(_ error: Error) -> Bool {
        let message: String
        switch error {
        case AppStoreConnectError.apiError(let apiMessage):
            message = apiMessage
        case AppStoreConnectError.httpError(let statusCode, let body):
            guard statusCode == 409 || statusCode == 422 else { return false }
            message = body
        default:
            return false
        }

        let normalized = message.lowercased()
        return (normalized.contains("reviewsubmission") || normalized.contains("review submission"))
            && (normalized.contains("already") || normalized.contains("exists"))
    }
}
