import Foundation
import MCP

struct ReleaseStatusHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let appID) = args["app_id"] else {
            throw AppStoreConnectError.invalidArgument("app_id is required")
        }
        let versionID: String? = if case .string(let v) = args["version_id"] { v } else { nil }
        let platform: String = if case .string(let v) = args["platform"] { v } else { "IOS" }

        let version = try await resolveVersion(appID: appID, versionID: versionID, platform: platform)
        let build = try await fetchAttachedBuild(versionID: version.id)
        let localizations = try await listLocalizations(versionID: version.id)

        var output = """
        Release Status for v\(version.attributes.versionString ?? "?") [\(version.id)]
        Platform: \(version.attributes.platform ?? platform)
        State: \(version.attributes.appStoreState ?? "unknown")
        Release Type: \(version.attributes.releaseType ?? "not set")
        Copyright: \(version.attributes.copyright ?? "not set")

        Build:
        """

        if let build {
            let uploaded = build.attributes.uploadedDate ?? "unknown"
            output += "\n  \(build.attributes.buildNumber ?? "?") (v\(build.attributes.version ?? "?")) — \(build.attributes.processingState ?? "unknown") — uploaded \(uploaded)"
        } else {
            output += "\n  No build attached"
        }

        output += "\n\nLocalizations (\(localizations.count)):"
        if localizations.isEmpty {
            output += "\n  None"
        } else {
            for loc in localizations {
                let locale = loc.attributes.locale ?? "?"
                let desc = fieldStatus(loc.attributes.description)
                let whatsNew = fieldStatus(loc.attributes.whatsNew)
                let support = fieldStatus(loc.attributes.supportUrl)
                output += "\n  \(locale): description \(desc), whatsNew \(whatsNew), supportUrl \(support)"
            }
        }

        return CallTool.Result(content: [.text(output)])
    }

    private func resolveVersion(appID: String, versionID: String?, platform: String) async throws -> AppStoreVersion {
        if let versionID {
            let response = try await client.get(
                Endpoints.appStoreVersion(id: versionID),
                as: APIResponse<AppStoreVersion>.self
            )
            return response.data
        }

        let response = try await client.get(
            Endpoints.appStoreVersions(appID: appID, platform: platform),
            as: APIListResponse<AppStoreVersion>.self
        )
        guard let latest = response.data.first else {
            throw AppStoreConnectError.invalidArgument("No versions found for app \(appID) on \(platform)")
        }
        return latest
    }

    private func fetchAttachedBuild(versionID: String) async throws -> Build? {
        do {
            let response = try await client.get(
                Endpoints.versionBuild(versionID: versionID),
                as: APIResponse<Build>.self
            )
            return response.data
        } catch let error as AppStoreConnectError {
            if case .httpError(statusCode: 404, _) = error { return nil }
            throw error
        }
    }

    private func listLocalizations(versionID: String) async throws -> [AppStoreVersionLocalization] {
        let response = try await client.get(
            Endpoints.appStoreVersionLocalizations(versionID: versionID),
            as: APIListResponse<AppStoreVersionLocalization>.self
        )
        return response.data
    }

    private func fieldStatus(_ value: String?) -> String {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return "MISSING"
        }
        return "OK"
    }
}
