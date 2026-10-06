import MCP

struct ListAppInfosHandler: Sendable {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let appID = try MetadataArguments.requiredID("app_id", in: params)
        let infos = try await client.getAll(Endpoints.appInfos(appID: appID), as: APIListResponse<AppInfo>.self)
        let output = infos.isEmpty ? "No app info records found for app [\(appID)]." :
            "App info records for app [\(appID)]:\n\n" + infos.map(MetadataFormatting.appInfo).joined(separator: "\n\n")
        return CallTool.Result(content: [.text(output)])
    }
}
