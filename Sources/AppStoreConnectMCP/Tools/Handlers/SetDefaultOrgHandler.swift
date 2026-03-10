import Foundation
import MCP

struct SetDefaultOrgHandler {
    let registry: OrganizationRegistry

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let orgName = params.arguments?["org_name"]?.stringValue, !orgName.isEmpty else {
            throw AppStoreConnectError.invalidArgument("org_name is required")
        }

        try await registry.setDefault(orgName)
        return CallTool.Result(content: [.text("Default organization set to '\(orgName)'")])
    }
}
