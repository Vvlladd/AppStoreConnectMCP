import Foundation

struct AppStoreReviewSubmission: Decodable, Sendable {
    let type: String
    let id: String
}

struct CreateSubmissionRequest: Encodable, Sendable {
    let data: Data

    struct Data: Encodable, Sendable {
        let type = "appStoreVersionSubmissions"
        let relationships: Relationships

        struct Relationships: Encodable, Sendable {
            let appStoreVersion: RelationshipData
        }
    }
}
