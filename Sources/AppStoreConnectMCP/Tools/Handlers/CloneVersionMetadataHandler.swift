import Foundation
import MCP

struct CloneVersionMetadataHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let sourceVersionID) = args["source_version_id"] else {
            throw AppStoreConnectError.invalidArgument("source_version_id is required")
        }
        guard case .string(let targetVersionID) = args["target_version_id"] else {
            throw AppStoreConnectError.invalidArgument("target_version_id is required")
        }
        let localeFilter = extractLocaleFilter(args)

        let sourceLocalizations = try await listLocalizations(versionID: sourceVersionID)
        let targetLocalizations = try await listLocalizations(versionID: targetVersionID)

        let targetByLocale: [String: AppStoreVersionLocalization] = Dictionary(
            uniqueKeysWithValues: targetLocalizations.compactMap { loc in
                guard let locale = loc.attributes.locale else { return nil }
                return (locale, loc)
            }
        )

        let sources: [AppStoreVersionLocalization]
        if let localeFilter {
            sources = sourceLocalizations.filter { localeFilter.contains($0.attributes.locale ?? "") }
        } else {
            sources = sourceLocalizations
        }

        var createdCount = 0
        var updatedCount = 0

        for source in sources {
            guard let locale = source.attributes.locale else { continue }
            let attrs = source.attributes

            if let existing = targetByLocale[locale] {
                let body = UpdateLocalizationRequest(
                    data: .init(
                        id: existing.id,
                        attributes: .init(
                            description: attrs.description,
                            keywords: attrs.keywords,
                            whatsNew: attrs.whatsNew,
                            promotionalText: attrs.promotionalText,
                            marketingUrl: attrs.marketingUrl,
                            supportUrl: attrs.supportUrl
                        )
                    )
                )
                _ = try await client.patch(
                    Endpoints.appStoreVersionLocalization(id: existing.id),
                    body: body,
                    as: APIResponse<AppStoreVersionLocalization>.self
                )
                updatedCount += 1
            } else {
                let body = CreateLocalizationRequest(
                    data: .init(
                        attributes: .init(
                            locale: locale,
                            description: attrs.description,
                            keywords: attrs.keywords,
                            whatsNew: attrs.whatsNew,
                            promotionalText: attrs.promotionalText,
                            marketingUrl: attrs.marketingUrl,
                            supportUrl: attrs.supportUrl
                        ),
                        relationships: .init(
                            appStoreVersion: .init(
                                data: .init(type: "appStoreVersions", id: targetVersionID)
                            )
                        )
                    )
                )
                _ = try await client.post(
                    Endpoints.appStoreVersionLocalizationsCreate(),
                    body: body,
                    as: APIResponse<AppStoreVersionLocalization>.self
                )
                createdCount += 1
            }
        }

        let output = """
        Clone metadata: [\(sourceVersionID)] → [\(targetVersionID)]
        Locales processed: \(sources.count)
        Created: \(createdCount), Updated: \(updatedCount)
        """

        return CallTool.Result(content: [.text(output)])
    }

    private func listLocalizations(versionID: String) async throws -> [AppStoreVersionLocalization] {
        let response = try await client.get(
            Endpoints.appStoreVersionLocalizations(versionID: versionID),
            as: APIListResponse<AppStoreVersionLocalization>.self
        )
        return response.data
    }

    private func extractLocaleFilter(_ args: [String: Value]) -> Set<String>? {
        guard case .string(let raw) = args["locales"] else { return nil }
        let parsed = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return parsed.isEmpty ? nil : Set(parsed)
    }
}
