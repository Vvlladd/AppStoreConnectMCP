import Foundation
import MCP

// An actor keeps captured requests isolated while the real handlers await fixture responses.
actor AppStoreConnectClient {
    struct Request: Sendable {
        let url: URL
        let method: String
        let body: Data?
    }
    let responses: [String: String]
    private var requests: [Request] = []

    init(responses: [String: String]) { self.responses = responses }

    func get<T: Decodable & Sendable>(_ url: URL, as type: T.Type) throws -> T {
        requests.append(Request(url: url, method: "GET", body: nil))
        return try decode(url, as: type)
    }

    func getAll<T: Decodable & Sendable>(_ url: URL, as type: APIListResponse<T>.Type) throws -> [T] {
        var result: [T] = []
        var next: URL? = url
        while let url = next {
            let page = try get(url, as: type)
            result += page.data
            next = page.nextPageURL
        }
        return result
    }

    func patch<B: Encodable & Sendable, T: Decodable & Sendable>(_ url: URL, body: B, as type: T.Type) throws -> T {
        requests.append(Request(url: url, method: "PATCH", body: try JSONEncoder().encode(body)))
        return try decode(url, as: type)
    }

    func capturedRequests() -> [Request] { requests }

    func post<B: Encodable & Sendable, T: Decodable & Sendable>(_ url: URL, body: B, as type: T.Type) throws -> T {
        throw AppStoreConnectError.invalidArgument("Unexpected POST during a read-only release check")
    }

    func delete(_ url: URL) throws {
        throw AppStoreConnectError.invalidArgument("Unexpected DELETE during a read-only release check")
    }

    private func decode<T: Decodable>(_ url: URL, as type: T.Type) throws -> T {
        guard let json = responses[url.path + (url.query.map { "?" + $0 } ?? "")] ?? responses[url.path] else {
            throw AppStoreConnectError.httpError(statusCode: 404, body: "Fixture not found")
        }
        if json == "HTTP 403" { throw AppStoreConnectError.apiError("Forbidden") }
        return try JSONDecoder().decode(type, from: Data(json.utf8))
    }
}

@main
struct ReleaseMetadataTests {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
    }

    static func text(_ result: CallTool.Result) -> String {
        result.content.compactMap { if case .text(let text, _, _) = $0 { return text }; return nil }.joined()
    }

    static let versionJSON = #"""
    {"data":{"type":"appStoreVersions","id":"draft","attributes":{
    "versionString":"8.0.1","platform":"IOS","appVersionState":"PREPARE_FOR_SUBMISSION",
    "copyright":"2026","releaseType":"AFTER_APPROVAL"}}}
    """#
    static let localeOneJSON = #"""
    {"data":[{"type":"appStoreVersionLocalizations","id":"en","attributes":{
    "locale":"en-US","description":"English description","whatsNew":"Notes","supportUrl":"https://example.com"}}],
    "links":{"next":"https://api.appstoreconnect.apple.com/v1/appStoreVersions/draft/appStoreVersionLocalizations?cursor=2"}}
    """#
    static let localeTwoJSON = #"""
    {"data":[{"type":"appStoreVersionLocalizations","id":"de","attributes":{
    "locale":"de-DE","description":"German description","whatsNew":null,"supportUrl":null}}],"links":{"next":null}}
    """#

    static func releaseClient(build: String) -> AppStoreConnectClient {
        AppStoreConnectClient(responses: [
            "/v1/appStoreVersions/draft": versionJSON,
            "/v1/appStoreVersions/draft/build": build,
            "/v1/appStoreVersions/draft/appStoreVersionLocalizations": localeOneJSON,
            "/v1/appStoreVersions/draft/appStoreVersionLocalizations?cursor=2": localeTwoJSON,
        ])
    }

    static func main() async throws {
        let params = CallTool.Parameters(name: "release_status", arguments: ["app_id": .string("app"), "version_id": .string("draft")])
        let missing = releaseClient(build: #"{"data":null}"#)
        let status = text(try await ReleaseStatusHandler(client: missing).handle(params))
        expect(status.contains("No build attached"), "Null build must not cause a decoding error")
        expect(status.contains("State: PREPARE_FOR_SUBMISSION"), "Use current version state")
        expect(status.contains("Localizations (2)"), "Release status must fetch every localization page")
        let validation = text(try await ValidateForSubmissionHandler(client: missing).handle(params))
        expect(validation.contains("[FAIL] Build attached & valid: No build attached"), "A missing build is a failed check, not a tool error")
        expect(validation.contains("[PASS] Version state: PREPARE_FOR_SUBMISSION"), "Validate the current state field")
        expect(validation.contains("missing in de-DE"), "Incomplete locales on later pages must be checked")

        let attached = releaseClient(build: #"{"data":{"type":"builds","id":"build","attributes":{"version":"801","processingState":"VALID"}}}"#)
        let attachedStatus = text(try await ReleaseStatusHandler(client: attached).handle(params))
        expect(attachedStatus.contains("VALID") && !attachedStatus.contains("No build attached"), "Keep attached-build support")
        let attachedValidation = text(try await ValidateForSubmissionHandler(client: attached).handle(params))
        expect(attachedValidation.contains("[PASS] Build attached & valid:"), "A valid build must pass")
        for payload in [#"{"data":{"type":"builds","id":"broken"}}"#, "HTTP 403"] {
            do {
                _ = try await ReleaseStatusHandler(client: releaseClient(build: payload)).handle(params)
                preconditionFailure("Malformed data and authorization errors must propagate")
            } catch { }
            do {
                _ = try await ValidateForSubmissionHandler(client: releaseClient(build: payload)).handle(params)
                preconditionFailure("Validation must propagate malformed data and authorization errors")
            } catch { }
        }

        let infoID = "116c7716-5a8e-4605-a956-66dfe1f45ce5"
        let appInfoClient = AppStoreConnectClient(responses: [
            "/v1/appInfos/\(infoID)/appInfoLocalizations": #"""
            {"data":[],"links":{"next":"https://api.appstoreconnect.apple.com/v1/appInfos/page-two/appInfoLocalizations"}}
            """#,
            "/v1/appInfos/page-two/appInfoLocalizations": #"""
            {"data":[{"type":"appInfoLocalizations","id":"loc-en","attributes":{"locale":"en-US","name":"Old name","subtitle":"Keep subtitle"}}]}
            """#,
            "/v1/appInfoLocalizations/loc-en": #"""
            {"data":{"type":"appInfoLocalizations","id":"loc-en","attributes":{"locale":"en-US","name":"New name","subtitle":"Keep subtitle"}}}
            """#,
        ])
        let update = CallTool.Parameters(name: "update_app_info_localization", arguments: [
            "app_info_id": .string(infoID), "locale": .string("en-US"), "name": .string("New name"),
        ])
        let updated = text(try await UpdateAppInfoLocalizationHandler(client: appInfoClient).handle(update))
        expect(updated.contains("Name: New name"), "Return updated localization")
        let requests = await appInfoClient.capturedRequests()
        expect(requests.count == 3 && requests[2].method == "PATCH", "Resolve every page before updating the locale")
        expect(requests[2].url.path == "/v1/appInfoLocalizations/loc-en", "PATCH localization ID, not app-info ID")
        let body = try JSONSerialization.jsonObject(with: requests[2].body!) as! [String: Any]
        let data = body["data"] as! [String: Any]
        let attributes = data["attributes"] as! [String: Any]
        expect(data["type"] as? String == "appInfoLocalizations" && data["id"] as? String == "loc-en", "JSON:API identifiers")
        expect(attributes["name"] as? String == "New name" && attributes["subtitle"] == nil, "Omit unspecified subtitle from PATCH")
        let clear = UpdateAppInfoLocalizationRequest(data: .init(id: "loc-en", attributes: .init(name: nil, subtitle: "")))
        let clearBody = try JSONSerialization.jsonObject(with: JSONEncoder().encode(clear)) as! [String: Any]
        let clearAttributes = (clearBody["data"] as! [String: Any])["attributes"] as! [String: Any]
        expect(clearAttributes["subtitle"] as? String == "" && clearAttributes["name"] == nil, "Allow clearing subtitle without overwriting name")

        let invalidClient = AppStoreConnectClient(responses: [:])
        for arguments: [String: Value] in [
            ["app_info_id": .string(infoID), "locale": .string("en-US")],
            ["app_info_id": .string(infoID), "locale": .string("en-US"), "name": .int(123)],
            ["app_info_id": .string(infoID), "locale": .string("en-US"), "name": .string("   ")],
            ["app_info_id": .string(infoID), "name": .string("New name")],
        ] {
            do {
                _ = try await UpdateAppInfoLocalizationHandler(client: invalidClient).handle(.init(name: "update_app_info_localization", arguments: arguments))
                preconditionFailure("Reject invalid inputs")
            } catch let error as AppStoreConnectError {
                guard case .invalidArgument = error else { throw error }
            }
        }
        let invalidRequests = await invalidClient.capturedRequests()
        expect(invalidRequests.isEmpty, "Invalid inputs must fail before any API request")
        print("PASS: null/attached builds, draft state, paginated release checks, propagated failures, and localized name/subtitle PATCH")
    }
}
