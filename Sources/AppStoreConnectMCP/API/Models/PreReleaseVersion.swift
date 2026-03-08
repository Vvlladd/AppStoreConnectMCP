import Foundation

struct PreReleaseVersion: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        let version: String?
    }
}
