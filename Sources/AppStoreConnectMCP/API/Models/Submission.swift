import Foundation

struct AppStoreReviewSubmission: Decodable, Sendable {
    let type: String
    let id: String
}

struct CreateSubmissionRequest: Encodable, Sendable {
    let data: RequestData

    struct RequestData: Encodable, Sendable {
        let type = "appStoreReviewSubmissions"
        let relationships: Relationships

        struct Relationships: Encodable, Sendable {
            let appStoreVersion: RelationshipData
        }
    }
}
