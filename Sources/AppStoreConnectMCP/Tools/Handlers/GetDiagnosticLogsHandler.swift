import Foundation
import MCP

struct GetDiagnosticLogsHandler {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let args = params.arguments else {
            throw AppStoreConnectError.invalidArgument("Missing arguments")
        }
        guard case .string(let signatureID) = args["signature_id"] else {
            throw AppStoreConnectError.invalidArgument("signature_id is required")
        }

        let response = try await client.get(
            Endpoints.diagnosticLogs(signatureID: signatureID),
            accept: "application/vnd.apple.xcode-metrics+json",
            as: DiagnosticLogsResponse.self
        )

        var output = ""
        guard let productData = response.productData, !productData.isEmpty else {
            return CallTool.Result(content: [.text("No diagnostic logs found for this signature.")])
        }

        for product in productData {
            guard let logs = product.diagnosticLogs, !logs.isEmpty else { continue }

            for (index, log) in logs.enumerated() {
                output += "--- Log \(index + 1) ---\n"

                if let meta = log.diagnosticMetaData {
                    output += "App: \(meta.bundleId ?? "?") v\(meta.appVersion ?? "?") (\(meta.buildVersion ?? "?"))\n"
                    output += "Device: \(meta.deviceType ?? "?") | OS: \(meta.osVersion ?? "?") | Arch: \(meta.platformArchitecture ?? "?")\n"
                    if let event = meta.event {
                        output += "Event: \(event)"
                        if let detail = meta.eventDetail { output += " (\(detail))" }
                        output += "\n"
                    }
                    if let writes = meta.writesCaused {
                        output += "Writes caused: \(writes)\n"
                    }
                }

                if let trees = log.callStackTree {
                    for tree in trees {
                        output += "\nCall Stack:\n"
                        if let roots = tree.callStackRootFrames {
                            for root in roots {
                                formatCallStack(root, indent: 0, output: &output)
                            }
                        }
                    }
                }
                output += "\n"
            }
        }

        if output.isEmpty {
            output = "No diagnostic logs found for this signature."
        }

        return CallTool.Result(content: [.text(output)])
    }

    private func formatCallStack(_ node: DiagnosticLogCallStackNode, indent: Int, output: inout String) {
        let prefix = String(repeating: "  ", count: indent)
        let symbol = node.symbolName ?? "???"
        let binary = node.binaryName ?? ""
        let blame = node.isBlameFrame == true ? " [BLAME]" : ""
        let samples = node.sampleCount.map { " (samples: \($0))" } ?? ""

        var location = ""
        if let file = node.fileName {
            location += " \(file)"
            if let line = node.lineNumber {
                location += ":\(line)"
            }
        }

        output += "\(prefix)\(symbol) [\(binary)]\(location)\(blame)\(samples)\n"

        if let subFrames = node.subFrames {
            for frame in subFrames {
                formatCallStack(frame, indent: indent + 1, output: &output)
            }
        }
    }
}
