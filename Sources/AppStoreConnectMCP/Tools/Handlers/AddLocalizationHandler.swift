import Foundation
import MCP

struct AddLocalizationHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let versionID) = args["version_id"] else {
            throw AppStoreConnectError.invalidArgument("version_id is required")
        }
        guard case .string(let locale) = args["locale"] else {
            throw AppStoreConnectError.invalidArgument("locale is required")
        }

        let description: String? = if case .string(let v) = args["description"] { v } else { nil }
        let keywords: String? = if case .string(let v) = args["keywords"] { v } else { nil }
        let whatsNew: String? = if case .string(let v) = args["whats_new"] { v } else { nil }
        let promotionalText: String? = if case .string(let v) = args["promotional_text"] { v } else { nil }
        let marketingUrl: String? = if case .string(let v) = args["marketing_url"] { v } else { nil }
        let supportUrl: String? = if case .string(let v) = args["support_url"] { v } else { nil }

        // Check if localization already exists for this locale
        let existing = try await client.get(
            Endpoints.appStoreVersionLocalizations(versionID: versionID),
            as: APIListResponse<AppStoreVersionLocalization>.self
        )

        if let existingLoc = existing.data.first(where: { $0.attributes.locale == locale }) {
            // Update existing
            let body = UpdateLocalizationRequest(
                data: .init(
                    id: existingLoc.id,
                    attributes: .init(
                        description: description,
                        keywords: keywords,
                        whatsNew: whatsNew,
                        promotionalText: promotionalText,
                        marketingUrl: marketingUrl,
                        supportUrl: supportUrl
                    )
                )
            )
            let response = try await client.patch(
                Endpoints.appStoreVersionLocalization(id: existingLoc.id),
                body: body,
                as: APIResponse<AppStoreVersionLocalization>.self
            )
            return CallTool.Result(content: [.text(
                "Updated localization [\(response.data.id)] for locale \(locale)"
            )])
        } else {
            // Create new
            let body = CreateLocalizationRequest(
                data: .init(
                    attributes: .init(
                        locale: locale,
                        description: description,
                        keywords: keywords,
                        whatsNew: whatsNew,
                        promotionalText: promotionalText,
                        marketingUrl: marketingUrl,
                        supportUrl: supportUrl
                    ),
                    relationships: .init(
                        appStoreVersion: .init(data: .init(type: "appStoreVersions", id: versionID))
                    )
                )
            )
            let response = try await client.post(
                Endpoints.appStoreVersionLocalizationsCreate(),
                body: body,
                as: APIResponse<AppStoreVersionLocalization>.self
            )
            return CallTool.Result(content: [.text(
                "Created localization [\(response.data.id)] for locale \(locale)"
            )])
        }
    }
}
