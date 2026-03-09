import Foundation
import MCP

struct ToolRouter {
    private let listApps: ListAppsHandler
    private let createVersion: CreateVersionHandler
    private let listVersions: ListVersionsHandler
    private let updateVersion: UpdateVersionHandler
    private let addLocalization: AddLocalizationHandler
    private let listBuilds: ListBuildsHandler
    private let uploadBuild: UploadBuildHandler
    private let attachBuild: AttachBuildHandler
    private let prepareRelease: PrepareReleaseHandler
    private let submitForReview: SubmitForReviewHandler

    init(client: AppStoreConnectClient) {
        self.listApps = ListAppsHandler(client: client)
        self.createVersion = CreateVersionHandler(client: client)
        self.listVersions = ListVersionsHandler(client: client)
        self.updateVersion = UpdateVersionHandler(client: client)
        self.addLocalization = AddLocalizationHandler(client: client)
        self.listBuilds = ListBuildsHandler(client: client)
        self.uploadBuild = UploadBuildHandler(client: client)
        self.attachBuild = AttachBuildHandler(client: client)
        self.prepareRelease = PrepareReleaseHandler(client: client)
        self.submitForReview = SubmitForReviewHandler(client: client)
    }

    func route(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            switch params.name {
            case "list_apps": return try await listApps.handle(params)
            case "create_version": return try await createVersion.handle(params)
            case "list_versions": return try await listVersions.handle(params)
            case "update_version": return try await updateVersion.handle(params)
            case "add_localization": return try await addLocalization.handle(params)
            case "list_builds": return try await listBuilds.handle(params)
            case "upload_build": return try await uploadBuild.handle(params)
            case "attach_build": return try await attachBuild.handle(params)
            case "prepare_release": return try await prepareRelease.handle(params)
            case "submit_for_review": return try await submitForReview.handle(params)
            default:
                return CallTool.Result(
                    content: [.text("Unknown tool: \(params.name)")],
                    isError: true
                )
            }
        } catch {
            return CallTool.Result(
                content: [.text("Error: \(error.localizedDescription)")],
                isError: true
            )
        }
    }
}
