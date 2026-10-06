import MCP

struct ListVersionLocalizationsHandler: Sendable {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let versionID = try MetadataArguments.requiredID("version_id", in: params)
        let locale = try MetadataArguments.locale(in: params)
        let localizations = try await client.getAll(
            Endpoints.appStoreVersionLocalizations(versionID: versionID, locale: locale),
            as: APIListResponse<AppStoreVersionLocalization>.self
        )
        let output = localizations.isEmpty ? "No version localizations found for version [\(versionID)]." :
            "Localizations for version [\(versionID)]:\n\n" +
            localizations.map(MetadataFormatting.versionLocalization).joined(separator: "\n\n")
        return CallTool.Result(content: [.text(output)])
    }
}
