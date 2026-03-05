import Foundation

struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let data: T
}

struct APIListResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let data: [T]
    let links: Links?
    let meta: Meta?

    struct Links: Decodable, Sendable {
        let next: String?
        let first: String?
        let `self`: String?
    }

    struct Meta: Decodable, Sendable {
        let paging: Paging?

        struct Paging: Decodable, Sendable {
            let total: Int?
            let limit: Int?
        }
    }

    var hasNextPage: Bool {
        links?.next != nil
    }

    var nextPageURL: URL? {
        guard let next = links?.next else { return nil }
        return URL(string: next)
    }
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
