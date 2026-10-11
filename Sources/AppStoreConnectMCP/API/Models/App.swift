import Foundation

struct App: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        let name: String
        let bundleId: String
        let sku: String?
        let primaryLocale: String?
        let contentRightsDeclaration: String?
        let isOrEverWasMadeForKids: Bool?
        let accessibilityUrl: String?
    }
}
