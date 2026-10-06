import MCP

struct GetAppHandler: Sendable {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let appID = try MetadataArguments.requiredID("app_id", in: params)
        let response = try await client.get(Endpoints.app(id: appID), as: APIResponse<App>.self)
        return CallTool.Result(content: [.text(MetadataFormatting.app(response.data))])
    }
}
