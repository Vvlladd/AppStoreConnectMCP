import Foundation
import MCP

struct ValidateForSubmissionHandler {
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

        var checks: [CheckResult] = []

        // 1. Version state
        let state = version.attributes.appStoreState ?? "unknown"
        let stateOK = state == "PREPARE_FOR_SUBMISSION"
        checks.append(CheckResult(
            name: "Version state",
            passed: stateOK,
            detail: stateOK ? state : "\(state) (must be PREPARE_FOR_SUBMISSION)"
        ))

        // 2. Copyright
        let copyrightOK = nonEmpty(version.attributes.copyright) != nil
        checks.append(CheckResult(
            name: "Copyright",
            passed: copyrightOK,
            detail: copyrightOK ? version.attributes.copyright! : "Not set"
        ))

        // 3. Build
        let buildOK = build?.attributes.processingState == "VALID"
        let buildDetail: String
        if let build, buildOK {
            buildDetail = "Build \(build.attributes.buildNumber ?? "?") — VALID"
        } else if let build {
            buildDetail = "Build \(build.attributes.buildNumber ?? "?") — \(build.attributes.processingState ?? "unknown") (must be VALID)"
        } else {
            buildDetail = "No build attached"
        }
        checks.append(CheckResult(
            name: "Build attached & valid",
            passed: buildOK,
            detail: buildDetail
        ))

        // 4. Localization completeness
        var missingDescLocales: [String] = []
        var missingSupportLocales: [String] = []
        for loc in localizations {
            let locale = loc.attributes.locale ?? "?"
            if nonEmpty(loc.attributes.description) == nil || nonEmpty(loc.attributes.whatsNew) == nil {
                missingDescLocales.append(locale)
            }
            if nonEmpty(loc.attributes.supportUrl) == nil {
                missingSupportLocales.append(locale)
            }
        }

        let descOK = missingDescLocales.isEmpty && !localizations.isEmpty
        checks.append(CheckResult(
            name: "Descriptions & release notes",
            passed: descOK,
            detail: descOK
                ? "\(localizations.count)/\(localizations.count) locales complete"
                : localizations.isEmpty
                    ? "No localizations found"
                    : "missing in \(missingDescLocales.joined(separator: ", "))"
        ))

        let supportOK = missingSupportLocales.isEmpty && !localizations.isEmpty
        checks.append(CheckResult(
            name: "Support URL",
            passed: supportOK,
            detail: supportOK
                ? "\(localizations.count)/\(localizations.count) locales complete"
                : localizations.isEmpty
                    ? "No localizations found"
                    : "missing in \(missingSupportLocales.joined(separator: ", "))"
        ))

        // Format output
        let failCount = checks.filter { !$0.passed }.count
        var output = "Submission Validation for v\(version.attributes.versionString ?? "?") [\(version.id)]\n"

        for check in checks {
            let icon = check.passed ? "PASS" : "FAIL"
            output += "\n[\(icon)] \(check.name): \(check.detail)"
        }

        output += "\n\nResult: "
        if failCount == 0 {
            output += "READY FOR SUBMISSION"
        } else {
            output += "NOT READY (\(failCount) issue\(failCount == 1 ? "" : "s") found)"
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

    private func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

private struct CheckResult {
    let name: String
    let passed: Bool
    let detail: String
}
