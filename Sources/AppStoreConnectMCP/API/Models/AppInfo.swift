import Foundation

struct AppInfo: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes
    let relationships: Relationships?

    struct Attributes: Decodable, Sendable {
        let state: String?
        let appStoreState: String?
        let appStoreAgeRating: String?
        let australiaAgeRating: String?
        let brazilAgeRating: String?
        let brazilAgeRatingV2: String?
        let franceAgeRating: String?
        let koreaAgeRating: String?
    }

    struct Relationships: Decodable, Sendable {
        let primaryCategory: CategoryRelationship?
        let primarySubcategoryOne: CategoryRelationship?
        let primarySubcategoryTwo: CategoryRelationship?
        let secondaryCategory: CategoryRelationship?
        let secondarySubcategoryOne: CategoryRelationship?
        let secondarySubcategoryTwo: CategoryRelationship?
    }

    struct CategoryRelationship: Decodable, Sendable {
        let data: CategoryIdentifier?
    }

    struct CategoryIdentifier: Decodable, Sendable {
        let type: String
        let id: String
    }
}
