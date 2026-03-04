import Foundation

struct Build: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        let version: String?
        let uploadedDate: String?
        let processingState: String?
        let buildNumber: String?
        let minOsVersion: String?
    }
}
