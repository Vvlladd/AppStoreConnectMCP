import Foundation

struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let data: T
}

struct APIListResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let data: [T]
}

struct APIErrorResponse: Decodable, Sendable {
    let errors: [APIErrorDetail]?

    struct APIErrorDetail: Decodable, Sendable {
        let status: String?
        let title: String?
        let detail: String?
    }

    var message: String {
        errors?.map { $0.detail ?? $0.title ?? "Unknown error" }.joined(separator: "; ")
            ?? "Unknown API error"
    }
}

struct EmptyBody: Encodable, Sendable {}

struct RelationshipData: Encodable, Sendable {
    let data: ResourceIdentifier

    struct ResourceIdentifier: Encodable, Sendable {
        let type: String
        let id: String
    }
}
