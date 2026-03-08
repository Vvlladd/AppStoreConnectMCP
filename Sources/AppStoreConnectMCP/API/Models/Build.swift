import Foundation

struct Build: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes
    let relationships: Relationships?

    struct Attributes: Decodable, Sendable {
        let version: String?
        let uploadedDate: String?
        let processingState: String?
        let buildNumber: String?
        let minOsVersion: String?
    }

    struct Relationships: Decodable, Sendable {
        let preReleaseVersion: Relationship?

        struct Relationship: Decodable, Sendable {
            let data: ResourceID?

            struct ResourceID: Decodable, Sendable {
                let type: String
                let id: String
            }
        }
    }
}
