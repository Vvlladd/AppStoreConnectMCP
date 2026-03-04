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

    // MARK: - Private

    private func performRequest(
        url: URL, method: String, body: Data? = nil, isRetry: Bool = false
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
        if statusCode == 401 && !isRetry {
            _ = try await jwtGenerator.forceRefresh()
            return try await performRequest(url: url, method: method, body: body, isRetry: true)
        }

        // 429 → respect Retry-After
        if statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap(Double.init) ?? 5.0
            try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
            return try await performRequest(url: url, method: method, body: body, isRetry: true)
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
