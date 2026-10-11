import MCP

struct GetVersionHandler: Sendable {
    let client: AppStoreConnectClient

    func handle(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let versionID = try MetadataArguments.requiredID("version_id", in: params)
        let response = try await client.get(Endpoints.appStoreVersion(id: versionID), as: APIResponse<AppStoreVersion>.self)
        return CallTool.Result(content: [.text(MetadataFormatting.version(response.data))])
    }
}
