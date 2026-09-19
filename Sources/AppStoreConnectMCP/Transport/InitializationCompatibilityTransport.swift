import Foundation
import Logging
import MCP

/// Works around swift-sdk 0.12.1 decoding experimental capabilities as [String: String].
/// This server does not implement experimental client capabilities. Ignore their
/// structured values until the SDK supports arbitrary JSON capability values.
actor InitializationCompatibilityTransport: Transport {
    nonisolated let logger = Logger(label: "appstoreconnect.transport")
    private let underlying = StdioTransport()

    func connect() async throws {
        try await underlying.connect()
    }

    func disconnect() async {
        await underlying.disconnect()
    }

    func send(_ data: Data) async throws {
        try await underlying.send(data)
    }

    func receive() -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            // Bridge the SDK stream; cancellation of the consumer cancels this task.
            let task = Task {
                do {
                    for try await data in await underlying.receive() {
                        try Task.checkCancellation()
                        continuation.yield(Self.normalizeInitialization(data))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }

    nonisolated static func normalizeInitialization(_ data: Data) -> Data {
        guard var message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              message["method"] as? String == "initialize",
              var params = message["params"] as? [String: Any],
              var capabilities = params["capabilities"] as? [String: Any],
              let experimental = capabilities["experimental"] as? [String: Any],
              experimental.values.contains(where: { !($0 is String) })
        else { return data }

        capabilities["experimental"] = experimental.filter { $0.value is String }
        params["capabilities"] = capabilities
        message["params"] = params
        return (try? JSONSerialization.data(withJSONObject: message)) ?? data
    }
}
