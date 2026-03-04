import Foundation

struct Configuration: Sendable {
    let issuerID: String
    let keyID: String
    let privateKeyPath: String

    static func fromEnvironment() throws -> Configuration {
        guard let issuerID = ProcessInfo.processInfo.environment["ASC_ISSUER_ID"], !issuerID.isEmpty else {
            throw AppStoreConnectError.configuration("ASC_ISSUER_ID environment variable is not set")
        }
        guard let keyID = ProcessInfo.processInfo.environment["ASC_KEY_ID"], !keyID.isEmpty else {
            throw AppStoreConnectError.configuration("ASC_KEY_ID environment variable is not set")
        }
        guard let keyPath = ProcessInfo.processInfo.environment["ASC_PRIVATE_KEY_PATH"], !keyPath.isEmpty else {
            throw AppStoreConnectError.configuration("ASC_PRIVATE_KEY_PATH environment variable is not set")
        }
        return Configuration(issuerID: issuerID, keyID: keyID, privateKeyPath: keyPath)
    }
}
