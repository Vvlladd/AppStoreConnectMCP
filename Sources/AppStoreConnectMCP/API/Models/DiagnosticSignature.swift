import Foundation

struct DiagnosticSignature: Decodable, Sendable {
    let type: String
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        let diagnosticType: String?
        let signature: String?
        let weight: Double?
        let insight: Insight?

        struct Insight: Decodable, Sendable {
            let regression: String?
        }
    }
}
