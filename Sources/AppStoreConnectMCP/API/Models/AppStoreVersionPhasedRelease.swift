import Foundation

enum PhasedReleaseState: String, Codable, Sendable {
    case inactive = "INACTIVE"
    case active = "ACTIVE"
    case paused = "PAUSED"
    case complete = "COMPLETE"
}

struct AppStoreVersionPhasedRelease: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        let phasedReleaseState: PhasedReleaseState?
        let startDate: String?
        let totalPauseDuration: Int?
        let currentDayNumber: Int?
    }
}

struct CreatePhasedReleaseRequest: Encodable, Sendable {
    let data: RequestData

    struct RequestData: Encodable, Sendable {
        let type = "appStoreVersionPhasedReleases"
        let attributes: Attributes
        let relationships: Relationships

        struct Attributes: Encodable, Sendable {
            let phasedReleaseState: PhasedReleaseState
        }

        struct Relationships: Encodable, Sendable {
            let appStoreVersion: RelationshipData
        }
    }
}

struct UpdatePhasedReleaseRequest: Encodable, Sendable {
    let data: RequestData

    struct RequestData: Encodable, Sendable {
        let type = "appStoreVersionPhasedReleases"
        let id: String
        let attributes: Attributes

        struct Attributes: Encodable, Sendable {
            let phasedReleaseState: PhasedReleaseState
        }
    }
}

struct ResourceIdentifierResponse: Decodable, Sendable {
    let data: ResourceIdentifier

    struct ResourceIdentifier: Decodable, Sendable {
        let type: String
        let id: String
    }
}
