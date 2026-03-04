import Foundation

struct AppStoreVersion: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        let versionString: String?
        let platform: String?
        let appStoreState: String?
        let copyright: String?
        let releaseType: String?
        let createdDate: String?
    }
}

struct CreateVersionRequest: Encodable, Sendable {
    let data: Data

    struct Data: Encodable, Sendable {
        let type = "appStoreVersions"
        let attributes: Attributes
        let relationships: Relationships

        struct Attributes: Encodable, Sendable {
            let versionString: String
            let platform: String
            let copyright: String?
            let releaseType: String?
        }

        struct Relationships: Encodable, Sendable {
            let app: RelationshipData
        }
    }
}

struct UpdateVersionRequest: Encodable, Sendable {
    let data: Data

    struct Data: Encodable, Sendable {
        let type = "appStoreVersions"
        let id: String
        let attributes: Attributes

        struct Attributes: Encodable, Sendable {
            let copyright: String?
            let releaseType: String?
        }
    }
}
