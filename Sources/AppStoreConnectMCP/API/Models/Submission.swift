import Foundation

struct AppStoreVersionSubmissionLookup: Decodable, Sendable {
    let id: String
    let relationships: Relationships?

    struct Relationships: Decodable, Sendable {
        let app: AppRelationship?

        struct AppRelationship: Decodable, Sendable {
            let data: ResourceIdentifier?

            struct ResourceIdentifier: Decodable, Sendable {
                let type: String
                let id: String
            }
        }
    }
}

struct ReviewSubmission: Decodable, Sendable {
    let type: String
    let id: String
}

struct ReviewSubmissionItem: Decodable, Sendable {
    let type: String
    let id: String
}

struct CreateReviewSubmissionRequest: Encodable, Sendable {
    let data: RequestData

    init(appID: String) {
        data = RequestData(relationships: .init(app: .init(data: .init(type: "apps", id: appID))))
    }

    struct RequestData: Encodable, Sendable {
        let type = "reviewSubmissions"
        let relationships: Relationships

        struct Relationships: Encodable, Sendable {
            let app: RelationshipData
        }
    }
}

struct CreateReviewSubmissionItemRequest: Encodable, Sendable {
    let data: RequestData

    init(versionID: String, reviewSubmissionID: String) {
        data = RequestData(
            relationships: .init(
                appStoreVersion: .init(data: .init(type: "appStoreVersions", id: versionID)),
                reviewSubmission: .init(data: .init(type: "reviewSubmissions", id: reviewSubmissionID))
            )
        )
    }

    struct RequestData: Encodable, Sendable {
        let type = "reviewSubmissionItems"
        let relationships: Relationships

        struct Relationships: Encodable, Sendable {
            let appStoreVersion: RelationshipData
            let reviewSubmission: RelationshipData
        }
    }
}
