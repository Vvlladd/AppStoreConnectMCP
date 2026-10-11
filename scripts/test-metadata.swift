import Foundation

@main
struct MetadataTests {
    static func decode<T: Decodable>(_ json: String, as type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
    }

    static func main() throws {
        let app = try decode(#"""
        {"data":{"type":"apps","id":"123","attributes":{
          "name":"Café Notes","bundleId":"com.example.notes","sku":"notes",
          "primaryLocale":"en-US","contentRightsDeclaration":"DOES_NOT_USE_THIRD_PARTY_CONTENT",
          "isOrEverWasMadeForKids":false,"accessibilityUrl":"https://example.com/accessibility"}}}
        """#, as: APIResponse<App>.self).data
        let appOutput = MetadataFormatting.app(app)
        expect(appOutput.contains("Name: Café Notes"), "App name must preserve Unicode")
        expect(appOutput.contains("Is or ever was made for kids: No"), "False must not look like an absent flag")
        expect(appOutput.contains("Content rights declaration: DOES_NOT_USE_THIRD_PARTY_CONTENT"), "Content rights missing")

        let infos = try decode(#"""
        {"data":[{"type":"appInfos","id":"info-live","attributes":{
          "state":"READY_FOR_DISTRIBUTION","appStoreState":"READY_FOR_SALE","appStoreAgeRating":"FOUR_PLUS",
          "brazilAgeRating":"L","brazilAgeRatingV2":"TEN"},"relationships":{
          "primaryCategory":{"data":{"type":"appCategories","id":"PRODUCTIVITY"}},
          "secondaryCategory":{"data":null}}}],
          "links":{"next":"https://api.appstoreconnect.apple.com/v1/apps/123/appInfos?cursor=next"},
          "meta":{"paging":{"total":2,"limit":1}}}
        """#, as: APIListResponse<AppInfo>.self)
        let infoOutput = MetadataFormatting.appInfo(infos.data[0])
        expect(infoOutput.contains("State: READY_FOR_DISTRIBUTION"), "Prefer the current state field")
        expect(infoOutput.contains("Primary category ID: PRODUCTIVITY"), "Decode category linkage")
        expect(infoOutput.contains("Secondary category ID: (not set)"), "Handle null category linkage")
        expect(infoOutput.contains("Brazil age rating: TEN"), "Prefer the current Brazil rating")
        expect(infos.hasNextPage && infos.nextPageURL?.query == "cursor=next", "Retain pagination links")

        let names = try decode(#"""
        {"data":[{"type":"appInfoLocalizations","id":"name-fr","attributes":{
          "locale":"fr-FR","name":"Carnet de café","subtitle":"Toutes vos idées",
          "privacyPolicyUrl":"https://example.com/privacy","privacyChoicesUrl":"https://example.com/choices",
          "privacyPolicyText":"First paragraph.\nSecond paragraph."}},
          {"type":"appInfoLocalizations","id":"name-empty","attributes":{"locale":"de-DE","name":null,"subtitle":""}}],
          "links":{"next":null}}
        """#, as: APIListResponse<AppInfoLocalization>.self)
        let nameOutput = MetadataFormatting.appInfoLocalization(names.data[0])
        expect(nameOutput.contains("[name-fr] fr-FR"), "Identify the localization and locale")
        expect(nameOutput.contains("Name: Carnet de café"), "Localized name missing")
        expect(nameOutput.contains("Subtitle: Toutes vos idées"), "Subtitle missing")
        expect(nameOutput.contains("Privacy choices URL: https://example.com/choices"), "Privacy choices missing")
        expect(nameOutput.contains("First paragraph.\nSecond paragraph."), "Preserve multiline privacy text")
        let emptyOutput = MetadataFormatting.appInfoLocalization(names.data[1])
        expect(emptyOutput.contains("Name: (not set)") && emptyOutput.contains("Subtitle: (not set)"), "Handle absent, null, and empty fields")
        expect(!names.hasNextPage, "Null next link ends pagination")

        let version = try decode(#"""
        {"data":{"type":"appStoreVersions","id":"version-2","attributes":{
          "versionString":"2.0","platform":"IOS","appVersionState":"READY_FOR_DISTRIBUTION",
          "appStoreState":"READY_FOR_SALE","copyright":"2026 Example","releaseType":"SCHEDULED",
          "earliestReleaseDate":"2026-10-10T00:00:00Z","createdDate":"2026-10-06T00:00:00Z",
          "reviewType":"APP_STORE","usesIdfa":false,"downloadable":true}}}
        """#, as: APIResponse<AppStoreVersion>.self).data
        let versionOutput = MetadataFormatting.version(version)
        expect(versionOutput.contains("State: READY_FOR_DISTRIBUTION"), "Prefer current version state")
        expect(versionOutput.contains("Earliest release date: 2026-10-10T00:00:00Z"), "Release date missing")
        expect(versionOutput.contains("Uses IDFA: No") && versionOutput.contains("Downloadable: Yes"), "Version flags missing")
        let legacy = try decode(#"{"type":"appStoreVersions","id":"old","attributes":{"appStoreState":"PREPARE_FOR_SUBMISSION"}}"#, as: AppStoreVersion.self)
        expect(MetadataFormatting.version(legacy).contains("State: PREPARE_FOR_SUBMISSION"), "Support legacy version responses")

        let localizations = try decode(#"""
        {"data":[{"type":"appStoreVersionLocalizations","id":"loc-en","attributes":{
          "locale":"en-US","keywords":"notes,café,ideas","description":"Paragraph one.\nParagraph two.",
          "whatsNew":"New widgets.","promotionalText":"Capture every idea.",
          "marketingUrl":"https://example.com","supportUrl":"https://example.com/support"}}]}
        """#, as: APIListResponse<AppStoreVersionLocalization>.self)
        let text = MetadataFormatting.versionLocalization(localizations.data[0])
        for field in ["Keywords: notes,café,ideas", "Description: Paragraph one.\nParagraph two.",
                      "What's new: New widgets.", "Promotional text: Capture every idea.",
                      "Marketing URL: https://example.com", "Support URL: https://example.com/support"] {
            expect(text.contains(field), "Missing localization field: \(field)")
        }
        let longDescription = String(repeating: "Long metadata.\n", count: 1000)
        let long = AppStoreVersionLocalization(type: "appStoreVersionLocalizations", id: "long", attributes: .init(
            locale: "en-US", description: longDescription, keywords: nil, whatsNew: nil,
            promotionalText: nil, marketingUrl: nil, supportUrl: nil
        ))
        expect(MetadataFormatting.versionLocalization(long).contains(longDescription), "Never truncate metadata")

        expect(Endpoints.app(id: "123").path == "/v1/apps/123", "App URL")
        expect(Endpoints.appInfos(appID: "123").path == "/v1/apps/123/appInfos", "App-info URL")
        let nameURL = Endpoints.appInfoLocalizations(appInfoID: "info-live", locale: "fr-FR")
        expect(nameURL.path == "/v1/appInfos/info-live/appInfoLocalizations", "App-info localization URL")
        let nameQuery = URLComponents(url: nameURL, resolvingAgainstBaseURL: false)?.queryItems
        expect(nameQuery == [URLQueryItem(name: "filter[locale]", value: "fr-FR")], "Name locale filter")
        let versionURL = Endpoints.appStoreVersionLocalizations(versionID: "version-2", locale: "en-US")
        expect(URLComponents(url: versionURL, resolvingAgainstBaseURL: false)?.queryItems == [URLQueryItem(name: "filter[locale]", value: "en-US")], "Version locale filter")
        expect(Endpoints.appStoreVersionLocalizations(versionID: "version-2").query == nil, "Preserve existing unfiltered URLs")
        print("PASS: metadata decoding, full text, nullable fields, current/legacy states, category IDs, pagination links, and locale URLs")
    }
}
