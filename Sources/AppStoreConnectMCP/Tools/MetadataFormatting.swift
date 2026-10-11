import Foundation

enum MetadataFormatting {
    private static func field(_ label: String, _ value: String?) -> String {
        "\(label): \(value.flatMap { $0.isEmpty ? nil : $0 } ?? "(not set)")"
    }

    private static func boolean(_ value: Bool?) -> String? {
        value.map { $0 ? "Yes" : "No" }
    }

    static func app(_ app: App) -> String {
        let a = app.attributes
        return [
            "App [\(app.id)]",
            field("Name", a.name),
            field("Bundle ID", a.bundleId),
            field("SKU", a.sku),
            field("Primary locale", a.primaryLocale),
            field("Content rights declaration", a.contentRightsDeclaration),
            field("Is or ever was made for kids", boolean(a.isOrEverWasMadeForKids)),
            field("Accessibility URL", a.accessibilityUrl),
        ].joined(separator: "\n")
    }

    static func appInfo(_ info: AppInfo) -> String {
        let a = info.attributes
        let r = info.relationships
        return [
            "App info [\(info.id)]",
            field("State", a.state ?? a.appStoreState),
            field("App Store age rating", a.appStoreAgeRating),
            field("Australia age rating", a.australiaAgeRating),
            field("Brazil age rating", a.brazilAgeRatingV2 ?? a.brazilAgeRating),
            field("France age rating", a.franceAgeRating),
            field("Korea age rating", a.koreaAgeRating),
            field("Primary category ID", r?.primaryCategory?.data?.id),
            field("Primary subcategory one ID", r?.primarySubcategoryOne?.data?.id),
            field("Primary subcategory two ID", r?.primarySubcategoryTwo?.data?.id),
            field("Secondary category ID", r?.secondaryCategory?.data?.id),
            field("Secondary subcategory one ID", r?.secondarySubcategoryOne?.data?.id),
            field("Secondary subcategory two ID", r?.secondarySubcategoryTwo?.data?.id),
        ].joined(separator: "\n")
    }

    static func appInfoLocalization(_ localization: AppInfoLocalization) -> String {
        let a = localization.attributes
        return [
            "[\(localization.id)] \(a.locale ?? "(unknown locale)")",
            field("Name", a.name),
            field("Subtitle", a.subtitle),
            field("Privacy policy URL", a.privacyPolicyUrl),
            field("Privacy choices URL", a.privacyChoicesUrl),
            field("Privacy policy text", a.privacyPolicyText),
        ].joined(separator: "\n")
    }

    static func version(_ version: AppStoreVersion) -> String {
        let a = version.attributes
        return [
            "Version [\(version.id)]",
            field("Version", a.versionString),
            field("Platform", a.platform),
            field("State", a.appVersionState ?? a.appStoreState),
            field("Copyright", a.copyright),
            field("Release type", a.releaseType),
            field("Earliest release date", a.earliestReleaseDate),
            field("Review type", a.reviewType),
            field("Uses IDFA", boolean(a.usesIdfa)),
            field("Downloadable", boolean(a.downloadable)),
            field("Created date", a.createdDate),
        ].joined(separator: "\n")
    }

    static func versionLocalization(_ localization: AppStoreVersionLocalization) -> String {
        let a = localization.attributes
        return [
            "[\(localization.id)] \(a.locale ?? "(unknown locale)")",
            field("Keywords", a.keywords),
            field("Description", a.description),
            field("What's new", a.whatsNew),
            field("Promotional text", a.promotionalText),
            field("Marketing URL", a.marketingUrl),
            field("Support URL", a.supportUrl),
        ].joined(separator: "\n")
    }
}
