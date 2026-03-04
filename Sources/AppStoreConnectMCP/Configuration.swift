import Foundation

enum AuthMode: String, Sendable {
    case team
    case individual

    static func fromEnvironment(_ value: String?) throws -> AuthMode {
        guard let value, !value.isEmpty else {
            return .team
        }

        switch value.lowercased() {
        case "team":
            return .team
        case "individual":
            return .individual
        default:
            throw AppStoreConnectError.configuration(
                "ASC_AUTH_MODE must be 'team' or 'individual'"
            )
        }
    }
}

struct Configuration: Sendable {
    let authMode: AuthMode
    let issuerID: String?
    let keyID: String
    let privateKeyPath: String

    static func fromEnvironment() throws -> Configuration {
        let authMode = try AuthMode.fromEnvironment(
            ProcessInfo.processInfo.environment["ASC_AUTH_MODE"]
        )

        let issuerID = ProcessInfo.processInfo.environment["ASC_ISSUER_ID"]
        
        guard let keyID = ProcessInfo.processInfo.environment["ASC_KEY_ID"], !keyID.isEmpty else {
            throw AppStoreConnectError.configuration("ASC_KEY_ID environment variable is not set")
        }
        guard let keyPath = ProcessInfo.processInfo.environment["ASC_PRIVATE_KEY_PATH"], !keyPath.isEmpty else {
            throw AppStoreConnectError.configuration("ASC_PRIVATE_KEY_PATH environment variable is not set")
        }
        
        switch authMode {
        case .team:
            guard let issuerID, !issuerID.isEmpty else {
                throw AppStoreConnectError.configuration(
                    "ASC_ISSUER_ID environment variable is required when ASC_AUTH_MODE=team"
                )
            }
            return Configuration(
                authMode: authMode,
                issuerID: issuerID,
                keyID: keyID,
                privateKeyPath: keyPath
            )
        case .individual:
            return Configuration(
                authMode: authMode,
                issuerID: nil,
                keyID: keyID,
                privateKeyPath: keyPath
            )
        }
    }
}
