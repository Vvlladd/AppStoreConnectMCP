import Foundation
import MCP

struct ListDiagnosticSignaturesHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let buildID) = args["build_id"] else {
            throw AppStoreConnectError.invalidArgument("build_id is required")
        }

        let diagnosticType: String? = if case .string(let v) = args["diagnostic_type"] { v } else { nil }

        if let diagnosticType {
            let valid = ["DISK_WRITES", "HANGS"]
            guard valid.contains(diagnosticType) else {
                throw AppStoreConnectError.invalidArgument("diagnostic_type must be DISK_WRITES or HANGS")
            }
        }

        let limit: Int
        if let n = args["limit"]?.intValue {
            limit = n
        } else {
            limit = 10
        }

        let response = try await client.get(
            Endpoints.diagnosticSignatures(buildID: buildID, diagnosticType: diagnosticType, limit: limit),
            as: APIListResponse<DiagnosticSignature>.self
        )

        let lines = response.data.map { sig in
            let type = sig.attributes.diagnosticType ?? "?"
            let name = sig.attributes.signature ?? "Unknown signature"
            let weight = sig.attributes.weight.map { String(format: "%.1f%%", $0 * 100) } ?? "?"
            return "[\(sig.id)] \(type) — \(name) (weight: \(weight))"
        }

        let output = lines.isEmpty
            ? "No diagnostic signatures found for this build."
            : lines.joined(separator: "\n")
        return CallTool.Result(content: [.text(output)])
    }
}
