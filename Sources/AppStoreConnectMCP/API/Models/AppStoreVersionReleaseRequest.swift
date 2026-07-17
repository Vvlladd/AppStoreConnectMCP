import Foundation

struct AppStoreVersionReleaseRequest: Decodable, Sendable {
    let type: String
    let id: String
}

struct CreateAppStoreVersionReleaseRequest: Encodable, Sendable {
    let data: RequestData

    init(versionID: String) {
        data = RequestData(
            relationships: .init(
                appStoreVersion: .init(
                    data: .init(type: "appStoreVersions", id: versionID)
                )
            )
        )
    }

    struct RequestData: Encodable, Sendable {
        let type = "appStoreVersionReleaseRequests"
        let relationships: Relationships

        struct Relationships: Encodable, Sendable {
            let appStoreVersion: RelationshipData
        }
    }
}
