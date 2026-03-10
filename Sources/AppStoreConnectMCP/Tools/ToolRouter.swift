import Foundation
import Logging
import MCP

struct ToolRouter: Sendable {
    private let registry: OrganizationRegistry
    private let logger = Logger(label: "appstoreconnect.router")

    init(registry: OrganizationRegistry) {
        self.registry = registry
    }

    func route(_ params: CallTool.Parameters) async -> CallTool.Result {
        logger.info("Tool called: \(params.name)")
        do {
            switch params.name {
            case "list_orgs":
                return try await ListOrgsHandler(registry: registry).handle(params)
            case "set_default_org":
                return try await SetDefaultOrgHandler(registry: registry).handle(params)
            default:
                let orgArg = try validateOrgArgument(params)
                let resolved = try await registry.clientAndOrgName(for: orgArg)
                let result = try await dispatchTool(params, client: resolved.client)
                return await prefixOrg(result, orgName: resolved.orgName)
            }
        } catch {
            logger.error("Tool \(params.name) failed: \(error.localizedDescription)")
            return CallTool.Result(
                content: [.text("Error: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    private func dispatchTool(_ params: CallTool.Parameters, client: AppStoreConnectClient) async throws -> CallTool.Result {
        switch params.name {
        case "list_apps": return try await ListAppsHandler(client: client).handle(params)
        case "create_version": return try await CreateVersionHandler(client: client).handle(params)
        case "list_versions": return try await ListVersionsHandler(client: client).handle(params)
        case "update_version": return try await UpdateVersionHandler(client: client).handle(params)
        case "add_localization": return try await AddLocalizationHandler(client: client).handle(params)
        case "list_builds": return try await ListBuildsHandler(client: client).handle(params)
        case "attach_build": return try await AttachBuildHandler(client: client).handle(params)
        case "prepare_release": return try await PrepareReleaseHandler(client: client).handle(params)
        case "submit_for_review": return try await SubmitForReviewHandler(client: client).handle(params)
        default:
            logger.warning("Unknown tool: \(params.name)")
            return CallTool.Result(
                content: [.text("Unknown tool: \(params.name)")],
                isError: true
            )
        }
    }

    private func validateOrgArgument(_ params: CallTool.Parameters) throws -> String? {
        guard let orgValue = params.arguments?["org"] else { return nil }
        guard let orgString = orgValue.stringValue else {
            throw AppStoreConnectError.invalidArgument("'org' must be a string")
        }
        return orgString
    }

    private func prefixOrg(_ result: CallTool.Result, orgName: String) async -> CallTool.Result {
        let orgCount = await registry.allOrganizations().count
        guard orgCount > 1 else { return result }
        let prefixed = result.content.map { content -> Tool.Content in
            if case .text(let text) = content {
                return .text("[org: \(orgName)] \(text)")
            }
            return content
        }
        return CallTool.Result(content: prefixed, isError: result.isError)
    }
}
