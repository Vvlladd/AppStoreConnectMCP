import Foundation

actor AppStoreConnectClient {
    private let jwtGenerator: JWTGenerator
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(jwtGenerator: JWTGenerator) {
        self.jwtGenerator = jwtGenerator
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - Generic Requests

    func get<T: Decodable & Sendable>(_ url: URL, as type: T.Type) async throws -> T {
        let data = try await performRequest(url: url, method: "GET")
        return try decode(data, as: type)
    }

    func post<Body: Encodable & Sendable, T: Decodable & Sendable>(
        _ url: URL, body: Body, as type: T.Type
    ) async throws -> T {
        let bodyData = try encoder.encode(body)
        let data = try await performRequest(url: url, method: "POST", body: bodyData)
        return try decode(data, as: type)
    }

    func patch<Body: Encodable & Sendable, T: Decodable & Sendable>(
        _ url: URL, body: Body, as type: T.Type
    ) async throws -> T {
        let bodyData = try encoder.encode(body)
        let data = try await performRequest(url: url, method: "PATCH", body: bodyData)
        return try decode(data, as: type)
    }

    func patchNoContent<Body: Encodable & Sendable>(_ url: URL, body: Body) async throws {
        let bodyData = try encoder.encode(body)
        _ = try await performRequest(url: url, method: "PATCH", body: bodyData)
    }

    /// Fetches all pages of a paginated list endpoint, returning the combined data array.
    func getAll<T: Decodable & Sendable>(_ url: URL, as type: APIListResponse<T>.Type) async throws -> [T] {
        var allItems: [T] = []
        var currentURL: URL? = url

        while let pageURL = currentURL {
            let response: APIListResponse<T> = try await get(pageURL, as: APIListResponse<T>.self)
            allItems.append(contentsOf: response.data)
            currentURL = response.nextPageURL
        }

        return allItems
    }

    // MARK: - Private

    private func performRequest(
        url: URL, method: String, body: Data? = nil,
        authRetried: Bool = false, rateLimitRetried: Bool = false
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let token = try await jwtGenerator.token()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body {
            request.httpBody = body
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppStoreConnectError.httpError(statusCode: 0, body: "Invalid response")
        }

        let statusCode = httpResponse.statusCode

        // 401 → refresh JWT and retry once
        if statusCode == 401 && !authRetried {
            _ = try await jwtGenerator.forceRefresh()
            return try await performRequest(
                url: url, method: method, body: body,
                authRetried: true, rateLimitRetried: rateLimitRetried
            )
        }

        // 429 → respect Retry-After, retry once (independent of auth retry)
        if statusCode == 429 && !rateLimitRetried {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap(Double.init) ?? 5.0
            try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
            return try await performRequest(
                url: url, method: method, body: body,
                authRetried: authRetried, rateLimitRetried: true
            )
        }

        guard (200...299).contains(statusCode) else {
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw AppStoreConnectError.apiError(errorResponse.message)
            }
            let bodyString = String(data: data, encoding: .utf8) ?? "No body"
            throw AppStoreConnectError.httpError(statusCode: statusCode, body: bodyString)
        }

        return data
    }

    private func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw AppStoreConnectError.decoding(error.localizedDescription)
        }
    }
}
