import MCP

struct ListAppInfoLocalizationsHandler: Sendable {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let appInfoID = try MetadataArguments.requiredID("app_info_id", in: params)
        let locale = try MetadataArguments.locale(in: params)
        let localizations = try await client.getAll(
            Endpoints.appInfoLocalizations(appInfoID: appInfoID, locale: locale),
            as: APIListResponse<AppInfoLocalization>.self
        )
        let output = localizations.isEmpty ? "No app info localizations found for app info [\(appInfoID)]." :
            "Localizations for app info [\(appInfoID)]:\n\n" +
            localizations.map(MetadataFormatting.appInfoLocalization).joined(separator: "\n\n")
        return CallTool.Result(content: [.text(output)])
    }
}
