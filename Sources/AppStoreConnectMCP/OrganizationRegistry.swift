import Foundation
import Logging

actor OrganizationRegistry {
    struct Organization: Sendable {
        let name: String
        let client: AppStoreConnectClient
        let authMode: AuthMode
    }

    private let organizations: [String: Organization]
    private var defaultOrgName: String
    private let logger: Logger

    init(organizations: [Organization], defaultOrgName: String, logger: Logger = Logger(label: "appstoreconnect.registry")) {
        var map: [String: Organization] = [:]
        for org in organizations {
            map[org.name] = org
        }
        self.organizations = map
        self.defaultOrgName = defaultOrgName
        self.logger = logger
    }

    func client(for orgName: String?) throws -> AppStoreConnectClient {
        let name = orgName ?? defaultOrgName
        guard let org = organizations[name] else {
            throw AppStoreConnectError.unknownOrganization(name)
        }
        return org.client
    }

    func organizationName(for orgName: String?) throws -> String {
        let name = orgName ?? defaultOrgName
        guard organizations[name] != nil else {
            throw AppStoreConnectError.unknownOrganization(name)
        }
        return name
    }

    func clientAndOrgName(for orgName: String?) throws -> (client: AppStoreConnectClient, orgName: String) {
        let name = orgName ?? defaultOrgName
        guard let org = organizations[name] else {
            throw AppStoreConnectError.unknownOrganization(name)
        }
        return (org.client, name)
    }

    func setDefault(_ name: String) throws {
        guard organizations[name] != nil else {
            throw AppStoreConnectError.unknownOrganization(name)
        }
        logger.info("Default organization changed to '\(name)'")
        defaultOrgName = name
    }

    func allOrganizations() -> [(name: String, authMode: AuthMode, isDefault: Bool)] {
        organizations.keys.sorted().map { name in
            (name: name, authMode: organizations[name]!.authMode, isDefault: name == defaultOrgName)
        }
    }
}
