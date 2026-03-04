import Foundation

struct AppStoreVersionLocalization: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        let locale: String?
        let description: String?
        let keywords: String?
        let whatsNew: String?
        let promotionalText: String?
        let marketingUrl: String?
        let supportUrl: String?
    }
}

struct CreateLocalizationRequest: Encodable, Sendable {
    let data: RequestData

    struct RequestData: Encodable, Sendable {
        let type = "appStoreVersionLocalizations"
        let attributes: Attributes
        let relationships: Relationships

        struct Attributes: Encodable, Sendable {
            let locale: String
            let description: String?
            let keywords: String?
            let whatsNew: String?
            let promotionalText: String?
            let marketingUrl: String?
            let supportUrl: String?
        }

        struct Relationships: Encodable, Sendable {
            let appStoreVersion: RelationshipData
        }
    }
}

struct UpdateLocalizationRequest: Encodable, Sendable {
    let data: RequestData

    struct RequestData: Encodable, Sendable {
        let type = "appStoreVersionLocalizations"
        let id: String
        let attributes: Attributes

        struct Attributes: Encodable, Sendable {
            let description: String?
            let keywords: String?
            let whatsNew: String?
            let promotionalText: String?
            let marketingUrl: String?
            let supportUrl: String?
        }
    }
}
