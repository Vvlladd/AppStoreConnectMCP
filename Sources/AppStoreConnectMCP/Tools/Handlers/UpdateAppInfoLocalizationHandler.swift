import Foundation
import MCP

struct UpdateAppInfoLocalizationHandler: Sendable {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let appInfoID = try MetadataArguments.requiredID("app_info_id", in: params)
        guard let locale = try MetadataArguments.locale(in: params) else {
            throw AppStoreConnectError.invalidArgument("locale is required")
        }
        let name = try MetadataArguments.optionalString("name", in: params)
        let subtitle = try MetadataArguments.optionalString("subtitle", in: params)
        guard name != nil || subtitle != nil else {
            throw AppStoreConnectError.invalidArgument("At least one of name or subtitle is required")
        }
        if let name, name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AppStoreConnectError.invalidArgument("name must not be empty")
        }

        let localizations = try await client.getAll(
            Endpoints.appInfoLocalizations(appInfoID: appInfoID, locale: locale),
            as: APIListResponse<AppInfoLocalization>.self
        )
        guard let localization = localizations.first(where: { $0.attributes.locale == locale }) else {
            throw AppStoreConnectError.invalidArgument("No existing localization for locale \(locale) in app info [\(appInfoID)]")
        }
        let body = UpdateAppInfoLocalizationRequest(data: .init(
            id: localization.id, attributes: .init(name: name, subtitle: subtitle)
        ))
        let response = try await client.patch(
            Endpoints.appInfoLocalization(id: localization.id), body: body,
            as: APIResponse<AppInfoLocalization>.self
        )
        return CallTool.Result(content: [.text(text:
            "Updated app info localization [\(response.data.id)] for locale \(locale) in app info [\(appInfoID)]\n\n" +
            MetadataFormatting.appInfoLocalization(response.data), annotations: nil, _meta: nil
        )])
    }
}
