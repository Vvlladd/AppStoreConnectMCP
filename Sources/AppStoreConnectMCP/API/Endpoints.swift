import Foundation

enum Endpoints {
    private static let base = "https://api.appstoreconnect.apple.com/v1"

    static func apps() -> URL {
        URL(string: "\(base)/apps")!
    }

    static func appStoreVersions(appID: String, platform: String? = nil) -> URL {
        var components = URLComponents(string: "\(base)/apps/\(appID)/appStoreVersions")!
        if let platform {
            components.queryItems = [URLQueryItem(name: "filter[platform]", value: platform)]
        }
        return components.url!
    }

    static func appStoreVersion(id: String) -> URL {
        URL(string: "\(base)/appStoreVersions/\(id)")!
    }

    static func appStoreVersionsCreate() -> URL {
        URL(string: "\(base)/appStoreVersions")!
    }

    static func appStoreVersionLocalizations(versionID: String) -> URL {
        URL(string: "\(base)/appStoreVersions/\(versionID)/appStoreVersionLocalizations")!
    }

    static func appStoreVersionLocalizationsCreate() -> URL {
        URL(string: "\(base)/appStoreVersionLocalizations")!
    }

    static func appStoreVersionLocalization(id: String) -> URL {
        URL(string: "\(base)/appStoreVersionLocalizations/\(id)")!
    }

    static func builds(appID: String, limit: Int = 10) -> URL {
        var components = URLComponents(string: "\(base)/builds")!
        components.queryItems = [
            URLQueryItem(name: "filter[app]", value: appID),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "sort", value: "-uploadedDate"),
        ]
        return components.url!
    }

    static func versionBuildRelationship(versionID: String) -> URL {
        URL(string: "\(base)/appStoreVersions/\(versionID)/relationships/build")!
    }

    static func appStoreReviewSubmissions() -> URL {
        URL(string: "\(base)/appStoreReviewSubmissions")!
    }
}
