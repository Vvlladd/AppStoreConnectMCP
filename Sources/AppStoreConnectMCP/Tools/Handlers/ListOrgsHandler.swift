import Foundation
import MCP

struct ListOrgsHandler {
    let registry: OrganizationRegistry

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let orgs = await registry.allOrganizations()

        let lines = orgs.map { org in
            let defaultMarker = org.isDefault ? " (default)" : ""
            return "\(org.name)\(defaultMarker) [auth: \(org.authMode.rawValue)]"
        }

        let output = lines.isEmpty ? "No organizations configured." : lines.joined(separator: "\n")
        return CallTool.Result(content: [.text(output)])
    }
}
