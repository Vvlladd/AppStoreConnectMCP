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

    static func appStoreVersion(id: String, includeApp: Bool = false) -> URL {
        var components = URLComponents(string: "\(base)/appStoreVersions/\(id)")!
        if includeApp {
            components.queryItems = [URLQueryItem(name: "include", value: "app")]
        }
        return components.url!
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
            URLQueryItem(name: "include", value: "preReleaseVersion"),
            URLQueryItem(name: "fields[preReleaseVersions]", value: "version"),
        ]
        return components.url!
    }

    static func buildUploads() -> URL {
        URL(string: "\(base)/buildUploads")!
    }

    static func buildUploadFiles() -> URL {
        URL(string: "\(base)/buildUploadFiles")!
    }

    static func buildUploadFile(id: String) -> URL {
        URL(string: "\(base)/buildUploadFiles/\(id)")!
    }

    static func versionBuild(versionID: String) -> URL {
        URL(string: "\(base)/appStoreVersions/\(versionID)/build")!
    }

    static func versionBuildRelationship(versionID: String) -> URL {
        URL(string: "\(base)/appStoreVersions/\(versionID)/relationships/build")!
    }

    static func reviewSubmissions() -> URL {
        URL(string: "\(base)/reviewSubmissions")!
    }

    static func reviewSubmissions(
        appID: String,
        states: [String]? = nil,
        limit: Int = 200
    ) -> URL {
        var components = URLComponents(string: "\(base)/reviewSubmissions")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "filter[app]", value: appID),
            URLQueryItem(name: "fields[reviewSubmissions]", value: "state,appStoreVersionForReview"),
            URLQueryItem(name: "include", value: "appStoreVersionForReview"),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        if let states, !states.isEmpty {
            queryItems.append(URLQueryItem(name: "filter[state]", value: states.joined(separator: ",")))
        }
        components.queryItems = queryItems
        return components.url!
    }

    static func reviewSubmission(id: String) -> URL {
        URL(string: "\(base)/reviewSubmissions/\(id)")!
    }

    static func reviewSubmissionItems() -> URL {
        URL(string: "\(base)/reviewSubmissionItems")!
    }

    // MARK: - Diagnostics

    static func diagnosticSignatures(buildID: String, diagnosticType: String? = nil, limit: Int = 10) -> URL {
        var components = URLComponents(string: "\(base)/builds/\(buildID)/diagnosticSignatures")!
        var items = [
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        if let diagnosticType {
            items.append(URLQueryItem(name: "filter[diagnosticType]", value: diagnosticType))
        }
        components.queryItems = items
        return components.url!
    }

    static func diagnosticLogs(signatureID: String) -> URL {
        URL(string: "\(base)/diagnosticSignatures/\(signatureID)/logs")!
    }

    // MARK: - Performance & Power Metrics

    static func perfPowerMetricsForApp(appID: String, metricType: String? = nil, platform: String? = nil) -> URL {
        var components = URLComponents(string: "\(base)/apps/\(appID)/perfPowerMetrics")!
        var items: [URLQueryItem] = []
        if let metricType {
            items.append(URLQueryItem(name: "filter[metricType]", value: metricType))
        }
        if let platform {
            items.append(URLQueryItem(name: "filter[platform]", value: platform))
        }
        if !items.isEmpty {
            components.queryItems = items
        }
        return components.url!
    }

    static func perfPowerMetricsForBuild(buildID: String, metricType: String? = nil, platform: String? = nil) -> URL {
        var components = URLComponents(string: "\(base)/builds/\(buildID)/perfPowerMetrics")!
        var items: [URLQueryItem] = []
        if let metricType {
            items.append(URLQueryItem(name: "filter[metricType]", value: metricType))
        }
        if let platform {
            items.append(URLQueryItem(name: "filter[platform]", value: platform))
        }
        if !items.isEmpty {
            components.queryItems = items
        }
        return components.url!
    }
}
