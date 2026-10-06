import Foundation

struct AppInfoLocalization: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        let locale: String?
        let name: String?
        let subtitle: String?
        let privacyPolicyUrl: String?
        let privacyChoicesUrl: String?
        let privacyPolicyText: String?
    }
}

struct UpdateAppInfoLocalizationRequest: Encodable, Sendable {
    let data: RequestData

    struct RequestData: Encodable, Sendable {
        let type = "appInfoLocalizations"
        let id: String
        let attributes: Attributes

        struct Attributes: Encodable, Sendable {
            let name: String?
            let subtitle: String?
        }
    }
}
