import Foundation
import MCP

struct PrepareReleaseHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let appID) = args["app_id"] else {
            throw AppStoreConnectError.invalidArgument("app_id is required")
        }
        guard case .string(let versionString) = args["version_string"] else {
            throw AppStoreConnectError.invalidArgument("version_string is required")
        }
        guard case .string(let platform) = args["platform"] else {
            throw AppStoreConnectError.invalidArgument("platform is required")
        }

        let copyright: String? = if case .string(let value) = args["copyright"] { value } else { nil }
        let releaseType: String? = if case .string(let value) = args["release_type"] { value } else { nil }
        let buildLimit = args["build_limit"]?.intValue ?? 100

        let versionsResponse = try await client.get(
            Endpoints.appStoreVersions(appID: appID, platform: platform),
            as: APIListResponse<AppStoreVersion>.self
        )

        let existingVersions = versionsResponse.data
        let previousVersion = selectPreviousVersion(from: existingVersions, excluding: versionString)

        var createdVersion = false
        let targetVersion: AppStoreVersion
        if let existingTarget = existingVersions.first(where: { $0.attributes.versionString == versionString }) {
            targetVersion = existingTarget
        } else {
            targetVersion = try await createVersion(
                appID: appID,
                versionString: versionString,
                platform: platform,
                copyright: copyright,
                releaseType: releaseType
            )
            createdVersion = true
        }

        var ready: [String] = []
        var missing: [String] = []

        if createdVersion {
            ready.append("Created version \(versionString) [\(targetVersion.id)]")
        } else {
            ready.append("Using existing version \(versionString) [\(targetVersion.id)]")
        }

        do {
            let metadataOutcome = try await synchronizeMetadata(
                targetVersion: targetVersion,
                previousVersion: previousVersion,
                explicitCopyright: copyright,
                explicitReleaseType: releaseType
            )
            ready.append(contentsOf: metadataOutcome.ready)
            missing.append(contentsOf: metadataOutcome.missing)
        } catch {
            missing.append("Metadata sync failed: \(error.localizedDescription)")
        }

        do {
            let buildOutcome = try await attachLatestValidBuild(
                appID: appID,
                targetVersion: targetVersion,
                versionString: versionString,
                buildLimit: buildLimit
            )
            ready.append(contentsOf: buildOutcome.ready)
            missing.append(contentsOf: buildOutcome.missing)
        } catch {
            missing.append("Build attachment failed: \(error.localizedDescription)")
        }

        let status = missing.isEmpty ? "ready" : "needs_attention"
        let output = """
        prepare_release: \(status)
        Version: \(versionString) [\(targetVersion.id)] on \(platform)

        Ready:
        \(formatList(ready))

        Missing:
        \(formatList(missing))
        """

        return CallTool.Result(content: [.text(output)])
    }

    private func createVersion(
        appID: String,
        versionString: String,
        platform: String,
        copyright: String?,
        releaseType: String?
    ) async throws -> AppStoreVersion {
        let body = CreateVersionRequest(
            data: .init(
                attributes: .init(
                    versionString: versionString,
                    platform: platform,
                    copyright: copyright,
                    releaseType: releaseType
                ),
                relationships: .init(
                    app: .init(data: .init(type: "apps", id: appID))
                )
            )
        )

        let response = try await client.post(
            Endpoints.appStoreVersionsCreate(),
            body: body,
            as: APIResponse<AppStoreVersion>.self
        )
        return response.data
    }

    private func synchronizeMetadata(
        targetVersion: AppStoreVersion,
        previousVersion: AppStoreVersion?,
        explicitCopyright: String?,
        explicitReleaseType: String?
    ) async throws -> StepOutcome {
        var ready: [String] = []
        var missing: [String] = []

        let currentLocalizations = try await listLocalizations(versionID: targetVersion.id)
        let previousLocalizations: [AppStoreVersionLocalization] = if let previousVersion {
            try await listLocalizations(versionID: previousVersion.id)
        } else {
            []
        }

        let desiredCopyright = explicitCopyright
            ?? nonEmpty(targetVersion.attributes.copyright)
            ?? nonEmpty(previousVersion?.attributes.copyright)
        let desiredReleaseType = explicitReleaseType
            ?? nonEmpty(targetVersion.attributes.releaseType)
            ?? nonEmpty(previousVersion?.attributes.releaseType)

        let shouldPatchVersion = desiredCopyright != nonEmpty(targetVersion.attributes.copyright)
            || desiredReleaseType != nonEmpty(targetVersion.attributes.releaseType)

        if shouldPatchVersion,
           desiredCopyright != nil || desiredReleaseType != nil {
            let body = UpdateVersionRequest(
                data: .init(
                    id: targetVersion.id,
                    attributes: .init(copyright: desiredCopyright, releaseType: desiredReleaseType)
                )
            )
            _ = try await client.patch(
                Endpoints.appStoreVersion(id: targetVersion.id),
                body: body,
                as: APIResponse<AppStoreVersion>.self
            )

            var details: [String] = []
            if desiredCopyright != nil {
                details.append("copyright")
            }
            if desiredReleaseType != nil {
                details.append("release type")
            }
            ready.append("Ensured version metadata: \(details.joined(separator: ", "))")
        } else if desiredCopyright != nil || desiredReleaseType != nil {
            ready.append("Version-level metadata already present")
        }

        if previousLocalizations.isEmpty {
            if currentLocalizations.isEmpty {
                missing.append("No previous version localizations found to copy, and target version has no localizations")
            } else {
                ready.append("Target version already has \(currentLocalizations.count) localization(s)")
            }
            return StepOutcome(ready: ready, missing: missing)
        }

        var targetByLocale: [String: AppStoreVersionLocalization] = Dictionary(
            uniqueKeysWithValues: currentLocalizations.compactMap { localization in
                guard let locale = localization.attributes.locale else { return nil }
                return (locale, localization)
            }
        )

        var createdCount = 0
        var updatedCount = 0
        var unchangedCount = 0

        for source in previousLocalizations {
            guard let locale = source.attributes.locale else { continue }

            if let existingTarget = targetByLocale[locale] {
                let merged = mergeLocalization(source: source.attributes, target: existingTarget.attributes)
                if merged.changed {
                    let body = UpdateLocalizationRequest(
                        data: .init(
                            id: existingTarget.id,
                            attributes: .init(
                                description: merged.content.description,
                                keywords: merged.content.keywords,
                                whatsNew: merged.content.whatsNew,
                                promotionalText: merged.content.promotionalText,
                                marketingUrl: merged.content.marketingUrl,
                                supportUrl: merged.content.supportUrl
                            )
                        )
                    )
                    _ = try await client.patch(
                        Endpoints.appStoreVersionLocalization(id: existingTarget.id),
                        body: body,
                        as: APIResponse<AppStoreVersionLocalization>.self
                    )
                    updatedCount += 1
                } else {
                    unchangedCount += 1
                }
            } else {
                let content = LocalizationContent(source: source.attributes)
                if content.hasAnyValue {
                    let body = CreateLocalizationRequest(
                        data: .init(
                            attributes: .init(
                                locale: locale,
                                description: content.description,
                                keywords: content.keywords,
                                whatsNew: content.whatsNew,
                                promotionalText: content.promotionalText,
                                marketingUrl: content.marketingUrl,
                                supportUrl: content.supportUrl
                            ),
                            relationships: .init(
                                appStoreVersion: .init(
                                    data: .init(type: "appStoreVersions", id: targetVersion.id)
                                )
                            )
                        )
                    )
                    let response = try await client.post(
                        Endpoints.appStoreVersionLocalizationsCreate(),
                        body: body,
                        as: APIResponse<AppStoreVersionLocalization>.self
                    )
                    targetByLocale[locale] = response.data
                    createdCount += 1
                }
            }
        }

        let finalLocalizationCount = targetByLocale.count
        ready.append(
            "Localization sync complete: \(finalLocalizationCount) locale(s) available, \(createdCount) created, \(updatedCount) updated, \(unchangedCount) unchanged"
        )

        return StepOutcome(ready: ready, missing: missing)
    }

    private func attachLatestValidBuild(
        appID: String,
        targetVersion: AppStoreVersion,
        versionString: String,
        buildLimit: Int
    ) async throws -> StepOutcome {
        let response = try await client.get(
            Endpoints.builds(appID: appID, limit: buildLimit),
            as: APIListResponse<Build>.self
        )

        let marketingVersionByID: [String: String] = Dictionary(
            uniqueKeysWithValues: (response.included ?? []).compactMap { prv in
                guard let version = prv.attributes.version else { return nil }
                return (prv.id, version)
            }
        )

        let candidate = response.data
            .filter { build in
                let prvID = build.relationships?.preReleaseVersion?.data?.id
                let marketingVersion = prvID.flatMap { marketingVersionByID[$0] }
                return marketingVersion == versionString
                    && build.attributes.processingState == "VALID"
            }
            .sorted(by: compareBuilds)
            .first

        guard let candidate else {
            return StepOutcome(
                ready: [],
                missing: ["No VALID build found for version \(versionString) in the latest \(buildLimit) build(s)"]
            )
        }

        try await client.patchNoContent(
            Endpoints.versionBuildRelationship(versionID: targetVersion.id),
            body: RelationshipData(data: .init(type: "builds", id: candidate.id))
        )

        let description = "Attached build [\(candidate.id)] v\(candidate.attributes.version ?? "?") build \(candidate.attributes.buildNumber ?? "?")"
        return StepOutcome(ready: [description], missing: [])
    }

    private func listLocalizations(versionID: String) async throws -> [AppStoreVersionLocalization] {
        let response = try await client.get(
            Endpoints.appStoreVersionLocalizations(versionID: versionID),
            as: APIListResponse<AppStoreVersionLocalization>.self
        )
        return response.data
    }

    private func selectPreviousVersion(
        from versions: [AppStoreVersion],
        excluding targetVersionString: String
    ) -> AppStoreVersion? {
        versions
            .filter { $0.attributes.versionString != targetVersionString }
            .sorted(by: compareVersions)
            .first
    }

    private func compareVersions(_ lhs: AppStoreVersion, _ rhs: AppStoreVersion) -> Bool {
        let lhsDate = parseDate(lhs.attributes.createdDate)
        let rhsDate = parseDate(rhs.attributes.createdDate)

        if let lhsDate, let rhsDate, lhsDate != rhsDate {
            return lhsDate > rhsDate
        }

        let lhsComponents = versionComponents(lhs.attributes.versionString)
        let rhsComponents = versionComponents(rhs.attributes.versionString)
        if lhsComponents != rhsComponents {
            return lhsComponents.lexicographicallyPrecedes(rhsComponents, by: >)
        }

        return lhs.id > rhs.id
    }

    private func compareBuilds(_ lhs: Build, _ rhs: Build) -> Bool {
        let lhsDate = parseDate(lhs.attributes.uploadedDate)
        let rhsDate = parseDate(rhs.attributes.uploadedDate)

        if let lhsDate, let rhsDate, lhsDate != rhsDate {
            return lhsDate > rhsDate
        }

        let lhsBuildNumber = Int(lhs.attributes.buildNumber ?? "") ?? 0
        let rhsBuildNumber = Int(rhs.attributes.buildNumber ?? "") ?? 0
        if lhsBuildNumber != rhsBuildNumber {
            return lhsBuildNumber > rhsBuildNumber
        }

        return lhs.id > rhs.id
    }

    private func mergeLocalization(
        source: AppStoreVersionLocalization.Attributes,
        target: AppStoreVersionLocalization.Attributes
    ) -> MergedLocalization {
        let original = LocalizationContent(source: target)
        var merged = original

        merged.description = merged.description ?? nonEmpty(source.description)
        merged.keywords = merged.keywords ?? nonEmpty(source.keywords)
        merged.whatsNew = merged.whatsNew ?? nonEmpty(source.whatsNew)
        merged.promotionalText = merged.promotionalText ?? nonEmpty(source.promotionalText)
        merged.marketingUrl = merged.marketingUrl ?? nonEmpty(source.marketingUrl)
        merged.supportUrl = merged.supportUrl ?? nonEmpty(source.supportUrl)

        return MergedLocalization(content: merged, changed: merged != original)
    }

    private func versionComponents(_ versionString: String?) -> [Int] {
        guard let versionString else { return [] }
        return versionString
            .split(separator: ".")
            .map { Int($0) ?? 0 }
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatterWithFractionalSeconds = ISO8601DateFormatter()
        formatterWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatterWithFractionalSeconds.date(from: value) {
            return date
        }

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        return fallbackFormatter.date(from: value)
    }

    private func formatList(_ items: [String]) -> String {
        if items.isEmpty {
            return "- none"
        }

        return items.map { "- \($0)" }.joined(separator: "\n")
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

private struct StepOutcome {
    let ready: [String]
    let missing: [String]
}

private struct MergedLocalization {
    let content: LocalizationContent
    let changed: Bool
}

private struct LocalizationContent: Equatable {
    var description: String?
    var keywords: String?
    var whatsNew: String?
    var promotionalText: String?
    var marketingUrl: String?
    var supportUrl: String?

    init(
        description: String? = nil,
        keywords: String? = nil,
        whatsNew: String? = nil,
        promotionalText: String? = nil,
        marketingUrl: String? = nil,
        supportUrl: String? = nil
    ) {
        self.description = description
        self.keywords = keywords
        self.whatsNew = whatsNew
        self.promotionalText = promotionalText
        self.marketingUrl = marketingUrl
        self.supportUrl = supportUrl
    }

    init(source: AppStoreVersionLocalization.Attributes) {
        self.description = Self.normalize(source.description)
        self.keywords = Self.normalize(source.keywords)
        self.whatsNew = Self.normalize(source.whatsNew)
        self.promotionalText = Self.normalize(source.promotionalText)
        self.marketingUrl = Self.normalize(source.marketingUrl)
        self.supportUrl = Self.normalize(source.supportUrl)
    }

    var hasAnyValue: Bool {
        description != nil
            || keywords != nil
            || whatsNew != nil
            || promotionalText != nil
            || marketingUrl != nil
            || supportUrl != nil
    }

    private static func normalize(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
