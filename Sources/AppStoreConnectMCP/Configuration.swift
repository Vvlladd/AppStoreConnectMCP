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
        let env = ProcessInfo.processInfo.environment
        return try buildConfiguration(
            authModeValue: env["ASC_AUTH_MODE"],
            issuerID: env["ASC_ISSUER_ID"],
            keyID: env["ASC_KEY_ID"],
            keyPath: env["ASC_PRIVATE_KEY_PATH"],
            context: "ASC"
        )
    }

    static func allFromEnvironment() throws -> (orgs: [(name: String, config: Configuration)], defaultOrg: String) {
        let env = ProcessInfo.processInfo.environment

        var orgNames = Set<String>()
        for key in env.keys {
            guard key.hasPrefix("ASC_ORG_") else { continue }
            let remainder = key.dropFirst("ASC_ORG_".count)
            for suffix in ["_ISSUER_ID", "_KEY_ID", "_PRIVATE_KEY_PATH", "_AUTH_MODE"] {
                if remainder.hasSuffix(suffix) {
                    let name = String(remainder.dropLast(suffix.count))
                    if !name.isEmpty {
                        orgNames.insert(name)
                    }
                    break
                }
            }
        }

        var orgs: [(name: String, config: Configuration)] = []

        if orgNames.isEmpty {
            let config = try fromEnvironment()
            orgs.append((name: "default", config: config))
            return (orgs: orgs, defaultOrg: "default")
        }

        for name in orgNames.sorted() {
            let prefix = "ASC_ORG_\(name)"
            let config = try buildConfiguration(
                authModeValue: env["\(prefix)_AUTH_MODE"],
                issuerID: env["\(prefix)_ISSUER_ID"],
                keyID: env["\(prefix)_KEY_ID"],
                keyPath: env["\(prefix)_PRIVATE_KEY_PATH"],
                context: prefix
            )
            orgs.append((name: name, config: config))
        }

        let defaultOrg = env["ASC_DEFAULT_ORG"] ?? orgs[0].name
        guard orgs.contains(where: { $0.name == defaultOrg }) else {
            throw AppStoreConnectError.configuration(
                "ASC_DEFAULT_ORG '\(defaultOrg)' does not match any configured organization"
            )
        }

        return (orgs: orgs, defaultOrg: defaultOrg)
    }

    private static func buildConfiguration(
        authModeValue: String?,
        issuerID: String?,
        keyID: String?,
        keyPath: String?,
        context: String
    ) throws -> Configuration {
        let authMode = try AuthMode.fromEnvironment(authModeValue)

        guard let keyID, !keyID.isEmpty else {
            throw AppStoreConnectError.configuration("\(context)_KEY_ID environment variable is not set")
        }
        guard let keyPath, !keyPath.isEmpty else {
            throw AppStoreConnectError.configuration("\(context)_PRIVATE_KEY_PATH environment variable is not set")
        }

        switch authMode {
        case .team:
            guard let issuerID, !issuerID.isEmpty else {
                throw AppStoreConnectError.configuration(
                    "\(context)_ISSUER_ID is required when auth mode is team"
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
